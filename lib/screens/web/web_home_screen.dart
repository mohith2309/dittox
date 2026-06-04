import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_notifications.dart';
import '../../model/pdfFile.dart';
import '../../model/shop.dart';
import '../../utils/auth_error_messages.dart';
import '../../utils/color_pallets.dart';
import '../../utils/browser_print_stub.dart'
    if (dart.library.html) '../../utils/browser_print_web.dart';
import '../../utils/demo_data.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/firestore_shop_service.dart';
import '../../utils/shop_auto_mode_store.dart';
import '../../utils/store_auth_store.dart';
import '../additional/favorites_screen.dart';
import '../additional/rewards_center_screen.dart';
import '../additional/settings_screen.dart';
import '../additional/support_center_screen.dart';

bool _isMissingRedirectState(FirebaseAuthException error) {
  final code = error.code.toLowerCase();
  final message = (error.message ?? '').toLowerCase();
  return code.contains('initial-state') ||
      message.contains('missing initial state');
}

Future<UserCredential?> _signInWithGoogleCredential() async {
  if (kIsWeb) {
    return FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }

  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) return null;
  final googleAuth = await googleUser.authentication;
  return FirebaseAuth.instance.signInWithCredential(
    GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    ),
  );
}

class WebHomeScreen extends StatefulWidget {
  final String? accessToken;
  final bool demoMode;

  const WebHomeScreen({
    super.key,
    required this.accessToken,
    required this.demoMode,
  });

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final _servicesKey = GlobalKey();
  final _storesKey = GlobalKey();
  final _quoteKey = GlobalKey();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  StreamSubscription<User?>? _authSub;
  String _service = 'Black and white documents';
  String _customerEmail = '';
  String _customerName = '';
  int _customerTab = -1;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _setCustomerFromUser(FirebaseAuth.instance.currentUser, notify: false);
    if (kIsWeb) unawaited(_completeGoogleRedirect());
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      _setCustomerFromUser(user);
    });
  }

  Future<void> _completeGoogleRedirect() async {
    try {
      final credential = await FirebaseAuth.instance.getRedirectResult();
      if (credential.user == null) return;
      await _saveCustomerCredential(credential);
      if (mounted) await _goToCustomerApp();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      if (_isMissingRedirectState(error)) return;
      _notifyError('Google sign-in failed', friendlyAuthError(error));
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _nameController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setCustomerFromUser(User? user, {bool notify = true}) {
    final nextEmail = user?.email ?? '';
    final nextName = user?.displayName ?? nextEmail.split('@').first;
    if (!mounted && notify) return;
    if (notify) {
      setState(() {
        _customerEmail = nextEmail;
        _customerName = nextName;
      });
    } else {
      _customerEmail = nextEmail;
      _customerName = nextName;
    }
  }

  void _notifySuccess(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addSuccess(title: title, body: body);
  }

  void _notifyWarning(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addWarning(title: title, body: body);
  }

  void _notifyError(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addError(title: title, body: body);
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  String _requestText() {
    return [
      'New Dittox web print request',
      'Name: ${_nameController.text.trim()}',
      'Contact: ${_contactController.text.trim()}',
      'Location: ${_locationController.text.trim()}',
      'Service: $_service',
      'Notes: ${_notesController.text.trim()}',
    ].join('\n');
  }

  bool _validateRequest() {
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    if (name.isEmpty || contact.isEmpty) {
      _notifyWarning('Missing details', 'Add your name and contact first.');
      return false;
    }
    return true;
  }

  Future<void> _sendRequest({required bool whatsapp}) async {
    if (!_validateRequest() || _sending) return;
    setState(() => _sending = true);
    try {
      final text = Uri.encodeComponent(_requestText());
      final uri = whatsapp
          ? Uri.parse('https://wa.me/919986537604?text=$text')
          : Uri.parse(
              'mailto:support@dittox.in?subject=Dittox%20print%20request&body=$text',
            );
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _notifyError('Contact app blocked', 'Could not open contact app.');
      } else if (mounted) {
        _notifySuccess('Request ready', 'Your print request is ready to send.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _saveCustomerCredential(UserCredential credential) async {
    final user = credential.user;
    final token = await user?.getIdToken(true);
    if (token != null && token.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('AccessToken', token);
    }
    _setCustomerFromUser(user);
    if (user != null && !user.emailVerified) {
      _notifyWarning(
        'Verify your email',
        'Signed in as ${user.email ?? 'your account'}. Check your inbox to verify and secure it.',
      );
    } else {
      _notifySuccess(
        'Customer app opened',
        'Signed in as ${user?.email ?? 'Dittox user'}.',
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final credential = await _signInWithGoogleCredential();
      if (credential == null) return;
      await _saveCustomerCredential(credential);
      await _goToCustomerApp();
    } on FirebaseAuthException catch (error) {
      _notifyError('Google sign-in failed', friendlyAuthError(error));
    } catch (_) {
      _notifyError(
          'Google sign-in failed', 'Could not complete Google sign-in.');
    }
  }

  Future<void> _goToStoreWebsite() async {
    final uri = Uri.base.resolve('/store');
    final opened = await launchUrl(uri, webOnlyWindowName: '_self');
    if (!opened && mounted) {
      _notifyError('Could not open store site', 'Try opening /store manually.');
    }
  }

  Future<void> _goToCustomerApp() async {
    final uri = Uri.base.resolve('/app');
    final opened = await launchUrl(uri, webOnlyWindowName: '_self');
    if (!opened && mounted) {
      _notifyError('Could not open app', 'Try opening /app manually.');
    }
  }

  Future<void> _showCustomerLogin() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit() async {
            final email = emailController.text.trim();
            final password = passwordController.text.trim();
            if (email.isEmpty || password.isEmpty || loading) return;
            setDialogState(() => loading = true);
            var dialogClosed = false;
            try {
              final credential =
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              await _saveCustomerCredential(credential);
              if (!dialogContext.mounted) return;
              dialogClosed = true;
              Navigator.of(dialogContext).pop();
              await _goToCustomerApp();
            } on FirebaseAuthException catch (error) {
              if (!mounted) return;
              _notifyError('Login failed', friendlyAuthError(error));
            } catch (_) {
              if (!mounted) return;
              _notifyError('Login failed', 'Login failed. Try again.');
            } finally {
              if (mounted && !dialogClosed) {
                setDialogState(() => loading = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Customer App Login'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign in to connect website requests with your Dittox app data.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              Navigator.of(dialogContext).pop();
                              await _signInWithGoogle();
                            },
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    loading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: loading ? null : submit,
                child: Text(loading ? 'Signing in...' : 'Login'),
              ),
            ],
          );
        },
      ),
    );

    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SelectionArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SingleChildScrollView(
              child: Column(
                children: [
                  _NavBar(
                    compact: width < 760,
                    onServices: () => _scrollTo(_servicesKey),
                    onStores: () => _scrollTo(_storesKey),
                    onQuote: () => _scrollTo(_quoteKey),
                    onCustomerLogin: _showCustomerLogin,
                    onStoreLogin: _goToStoreWebsite,
                  ),
                  _HeroSection(
                    wide: width >= 980,
                    onQuote: () => _scrollTo(_quoteKey),
                    onStores: () => _scrollTo(_storesKey),
                    onCustomerLogin: _showCustomerLogin,
                  ),
                  _CustomerAppSection(
                    wide: width >= 980,
                    signedIn: _customerEmail.isNotEmpty,
                    userLabel: _customerName.isNotEmpty
                        ? _customerName
                        : (_customerEmail.isNotEmpty
                            ? _customerEmail
                            : 'Guest'),
                    selectedTab: _customerTab,
                    onTabChanged: (index) =>
                        setState(() => _customerTab = index),
                    onEmailLogin: _showCustomerLogin,
                    onGoogleLogin: _signInWithGoogle,
                    onQuote: () => _scrollTo(_quoteKey),
                  ),
                  _StatsStrip(wide: width >= 820),
                  _AccessSection(
                    wide: width >= 900,
                    onCustomerLogin: _showCustomerLogin,
                    onStoreLogin: _goToStoreWebsite,
                  ),
                  _ServicesSection(key: _servicesKey, wide: width >= 900),
                  _StoreSection(
                    key: _storesKey,
                    wide: width >= 940,
                    onStoreLogin: _goToStoreWebsite,
                  ),
                  _QuoteSection(
                    key: _quoteKey,
                    wide: width >= 940,
                    nameController: _nameController,
                    contactController: _contactController,
                    locationController: _locationController,
                    notesController: _notesController,
                    service: _service,
                    sending: _sending,
                    onServiceChanged: (value) {
                      if (value == null) return;
                      setState(() => _service = value);
                    },
                    onEmail: () => _sendRequest(whatsapp: false),
                    onWhatsApp: () => _sendRequest(whatsapp: true),
                  ),
                  const _Footer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool compact;
  final VoidCallback onServices;
  final VoidCallback onStores;
  final VoidCallback onQuote;
  final VoidCallback onCustomerLogin;
  final VoidCallback onStoreLogin;

  const _NavBar({
    required this.compact,
    required this.onServices,
    required this.onStores,
    required this.onQuote,
    required this.onCustomerLogin,
    required this.onStoreLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.92),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 40,
        vertical: 18,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            children: [
              _Logo(compact: compact),
              const Spacer(),
              if (!compact) ...[
                _NavAction(label: 'Services', onTap: onServices),
                _NavAction(label: 'Store tools', onTap: onStores),
                _NavAction(label: 'App login', onTap: onCustomerLogin),
                _NavAction(label: 'Store login', onTap: onStoreLogin),
                _NavAction(label: 'Quote', onTap: onQuote),
                const SizedBox(width: 14),
              ],
              if (compact)
                IconButton(
                  tooltip: 'Login',
                  onPressed: onCustomerLogin,
                  icon: const Icon(Icons.account_circle_rounded),
                ),
              FilledButton(
                onPressed: onQuote,
                style: FilledButton.styleFrom(
                  backgroundColor: ColorPallets.deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(compact ? 'Quote' : 'Get print quote'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final bool compact;

  const _Logo({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ColorPallets.deepBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.print_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        if (!compact)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dittox',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ColorPallets.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Print orders online',
                style: TextStyle(
                  color: ColorPallets.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _NavAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: ColorPallets.textPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      child: Text(label),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool wide;
  final VoidCallback onQuote;
  final VoidCallback onStores;
  final VoidCallback onCustomerLogin;

  const _HeroSection({
    required this.wide,
    required this.onQuote,
    required this.onStores,
    required this.onCustomerLogin,
  });

  @override
  Widget build(BuildContext context) {
    final content = <Widget>[
      _HeroCopy(
        onQuote: onQuote,
        onStores: onStores,
        onCustomerLogin: onCustomerLogin,
      ),
      SizedBox(width: wide ? 36 : 0, height: wide ? 0 : 28),
      const _HeroPanel(),
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7FFFC), Color(0xFFEAF3FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: -120,
            child: _HeroGlow(
                size: wide ? 310 : 210, color: ColorPallets.lightBlue),
          ),
          const Positioned(
            left: -80,
            bottom: -110,
            child: _HeroGlow(size: 260, color: Color(0xFFB8F3DF)),
          ),
          _PageSection(
            padding:
                EdgeInsets.fromLTRB(24, wide ? 76 : 38, 24, wide ? 62 : 38),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 11, child: content[0]),
                      content[1],
                      Expanded(flex: 9, child: content[2]),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _HeroGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final VoidCallback onQuote;
  final VoidCallback onStores;
  final VoidCallback onCustomerLogin;

  const _HeroCopy({
    required this.onQuote,
    required this.onStores,
    required this.onCustomerLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Badge(label: 'Web print ordering + store queue platform'),
        const SizedBox(height: 22),
        Text(
          'Order prints online. Stores receive jobs instantly.',
          style: TextStyle(
            color: ColorPallets.textPrimary,
            fontSize: MediaQuery.sizeOf(context).width < 720 ? 42 : 68,
            height: 0.95,
            letterSpacing: -2.6,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Dittox gives customers a simple upload-to-pickup website and gives print stores a live web dashboard for accepting, printing, and completing jobs from any browser.',
          style: TextStyle(
            color: ColorPallets.textSecondary,
            fontSize: 18,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onQuote,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Start a print order'),
              style: FilledButton.styleFrom(
                backgroundColor: ColorPallets.deepBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onCustomerLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Open customer app'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPallets.deepBlue,
                side: const BorderSide(color: ColorPallets.deepBlue),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onStores,
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('Store dashboard'),
              style: TextButton.styleFrom(
                foregroundColor: ColorPallets.deepBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF063D3A), Color(0xFF123B72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: ColorPallets.deepBlue.withValues(alpha: 0.2),
            blurRadius: 36,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: ColorPallets.deepBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thesis_final.pdf',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: ColorPallets.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '86 pages - 1 copy - A4',
                            style: TextStyle(
                              color: ColorPallets.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _StatusPill(label: 'Printing'),
                  ],
                ),
                const SizedBox(height: 22),
                const _ProgressLine(step: 2),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Expanded(
                      child: _MetricCard(label: 'Queue position', value: '#03'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(label: 'Store ETA', value: '32 min'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child:
                    _DarkMetric(icon: Icons.sync_rounded, label: 'Live queue'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _DarkMetric(icon: Icons.lock_rounded, label: 'Secure'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _DarkMetric(
                    icon: Icons.receipt_long_rounded, label: 'Print ticket'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerAppSection extends StatelessWidget {
  final bool wide;
  final bool signedIn;
  final String userLabel;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onEmailLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onQuote;

  const _CustomerAppSection({
    required this.wide,
    required this.signedIn,
    required this.userLabel,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onEmailLogin,
    required this.onGoogleLogin,
    required this.onQuote,
  });

  @override
  Widget build(BuildContext context) {
    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 54),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: ColorPallets.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _CustomerSidebar(
                      signedIn: signedIn,
                      userLabel: userLabel,
                      selectedTab: selectedTab,
                      onTabChanged: onTabChanged,
                      onEmailLogin: onEmailLogin,
                      onGoogleLogin: onGoogleLogin,
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: _CustomerTabContent(
                      selectedTab: selectedTab,
                      signedIn: signedIn,
                      onQuote: onQuote,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _CustomerSidebar(
                    signedIn: signedIn,
                    userLabel: userLabel,
                    selectedTab: selectedTab,
                    onTabChanged: onTabChanged,
                    onEmailLogin: onEmailLogin,
                    onGoogleLogin: onGoogleLogin,
                  ),
                  _CustomerTabContent(
                    selectedTab: selectedTab,
                    signedIn: signedIn,
                    onQuote: onQuote,
                  ),
                ],
              ),
      ),
    );
  }
}

class _CustomerSidebar extends StatelessWidget {
  final bool signedIn;
  final String userLabel;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onEmailLogin;
  final VoidCallback onGoogleLogin;

  const _CustomerSidebar({
    required this.signedIn,
    required this.userLabel,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onEmailLogin,
    required this.onGoogleLogin,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.upload_file_rounded, 'Upload'),
      (Icons.storefront_rounded, 'Shops'),
      (Icons.receipt_long_rounded, 'Orders'),
      (Icons.account_balance_wallet_rounded, 'Wallet'),
    ];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF0D3537),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(34),
          bottomLeft: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DarkBadge(label: 'Customer app side'),
          const SizedBox(height: 18),
          Text(
            signedIn ? 'Welcome, $userLabel' : 'Run the Dittox app from web',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            signedIn
                ? 'Your web app workspace is active.'
                : 'Sign in to unlock the full customer workspace: uploads, shops, orders, and wallet.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onEmailLogin,
                icon: const Icon(Icons.login_rounded),
                label: Text(signedIn ? 'Switch account' : 'Email login'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ColorPallets.deepBlue,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onGoogleLogin,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final selected = selectedTab == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onTabChanged(index),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(tab.$1, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        tab.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CustomerTabContent extends StatelessWidget {
  final int selectedTab;
  final bool signedIn;
  final VoidCallback onQuote;

  const _CustomerTabContent({
    required this.selectedTab,
    required this.signedIn,
    required this.onQuote,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (selectedTab) {
      0 => 'Upload and configure documents',
      1 => 'Choose a nearby print store',
      2 => 'Track active and past orders',
      _ => 'Wallet and pay-later controls',
    };
    final body = switch (selectedTab) {
      0 =>
        'Drag-and-drop style web layout for PDFs, page ranges, copies, color pages, and binding choices.',
      1 =>
        'Firestore shop profiles can power store discovery with status, distance, ratings, and price preview.',
      2 =>
        'Customer order cards show pending, accepted, printing, ready, and collected states in a desktop layout.',
      _ =>
        'Wallet balance, PayLater dues, coupons, and Razorpay handoff stay organized for web users.',
    };
    final cards = switch (selectedTab) {
      0 => const [
          _MiniAppCard(Icons.picture_as_pdf_rounded, 'PDF upload',
              'Ready for web file picker'),
          _MiniAppCard(Icons.tune_rounded, 'Print settings',
              'Pages, copies, color, binding'),
          _MiniAppCard(Icons.receipt_rounded, 'Instant estimate',
              'Preview total before payment'),
        ],
      1 => const [
          _MiniAppCard(Icons.near_me_rounded, 'Nearby shops',
              'Sort by distance and price'),
          _MiniAppCard(
              Icons.star_rounded, 'Ratings', 'Show trusted stores first'),
          _MiniAppCard(
              Icons.schedule_rounded, 'Open hours', 'Avoid closed shops'),
        ],
      2 => const [
          _MiniAppCard(
              Icons.timeline_rounded, 'Live timeline', 'Accepted to pickup'),
          _MiniAppCard(Icons.notifications_active_rounded, 'Top-right alerts',
              'Samsung style web popups'),
          _MiniAppCard(
              Icons.history_rounded, 'History', 'Past jobs and reorder'),
        ],
      _ => const [
          _MiniAppCard(Icons.account_balance_wallet_rounded, 'Wallet',
              'Balance and credits'),
          _MiniAppCard(Icons.payments_rounded, 'PayLater', 'Track dues safely'),
          _MiniAppCard(
              Icons.local_offer_rounded, 'Coupons', 'Discounts and rewards'),
        ],
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ColorPallets.textPrimary,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: const TextStyle(
                        color: ColorPallets.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(label: signedIn ? 'Signed in' : 'Guest mode'),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 640;
              return narrow
                  ? Column(
                      children: cards
                          .map((card) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              ))
                          .toList(),
                    )
                  : Row(
                      children: cards
                          .map((card) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: card,
                                ),
                              ))
                          .toList(),
                    );
            },
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_rounded,
                    color: ColorPallets.deepBlue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This is the app-side web workspace. It stays separate from the marketing/request form and can grow into the full browser app.',
                    style: TextStyle(
                      color: ColorPallets.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                    onPressed: onQuote, child: const Text('Request now')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAppCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _MiniAppCard(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorPallets.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorPallets.deepBlue),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: ColorPallets.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: ColorPallets.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final bool wide;

  const _StatsStrip({required this.wide});

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('Firestore', 'Cloud orders and store profiles'),
      ('Hosting', 'Free Spark website deploy'),
      ('Responsive', 'Desktop, tablet, and mobile web'),
      ('No Functions', 'No Blaze billing required'),
    ];

    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 52),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: ColorPallets.cardBorder),
        ),
        child: wide
            ? Row(
                children: stats
                    .map(
                      (item) => Expanded(
                        child: _StatItem(title: item.$1, subtitle: item.$2),
                      ),
                    )
                    .toList(),
              )
            : Wrap(
                runSpacing: 16,
                children: stats
                    .map(
                      (item) => SizedBox(
                        width: MediaQuery.sizeOf(context).width / 2 - 36,
                        child: _StatItem(title: item.$1, subtitle: item.$2),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}

class _AccessSection extends StatelessWidget {
  final bool wide;
  final VoidCallback onCustomerLogin;
  final VoidCallback onStoreLogin;

  const _AccessSection({
    required this.wide,
    required this.onCustomerLogin,
    required this.onStoreLogin,
  });

  @override
  Widget build(BuildContext context) {
    final customer = _AccessCard(
      icon: Icons.phone_iphone_rounded,
      title: 'Customer app side',
      body:
          'Login from the website to connect Firebase Auth and keep app orders ready to sync.',
      buttonLabel: 'Customer login',
      buttonIcon: Icons.login_rounded,
      onTap: onCustomerLogin,
      filled: true,
    );
    final store = _AccessCard(
      icon: Icons.storefront_rounded,
      title: 'Store website side',
      body:
          'Store owners get a separate web portal entry for queue and profile tools.',
      buttonLabel: 'Store portal',
      buttonIcon: Icons.dashboard_rounded,
      onTap: onStoreLogin,
      filled: false,
    );

    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
      child: wide
          ? Row(
              children: [
                Expanded(child: customer),
                const SizedBox(width: 16),
                Expanded(child: store),
              ],
            )
          : Column(
              children: [
                customer,
                const SizedBox(height: 14),
                store,
              ],
            ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onTap;
  final bool filled;

  const _AccessCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: filled ? ColorPallets.deepBlue : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: filled ? ColorPallets.deepBlue : ColorPallets.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: filled ? 0.12 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: filled
                  ? Colors.white.withValues(alpha: 0.14)
                  : ColorPallets.deepBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: filled ? Colors.white : ColorPallets.deepBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: filled ? Colors.white : ColorPallets.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    color: filled
                        ? Colors.white.withValues(alpha: 0.78)
                        : ColorPallets.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                filled
                    ? FilledButton.icon(
                        onPressed: onTap,
                        icon: Icon(buttonIcon),
                        label: Text(buttonLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: ColorPallets.deepBlue,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: onTap,
                        icon: Icon(buttonIcon),
                        label: Text(buttonLabel),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  final bool wide;

  const _ServicesSection({super.key, required this.wide});

  @override
  Widget build(BuildContext context) {
    const cards = [
      _ServiceCardData(
        icon: Icons.file_copy_rounded,
        title: 'Document prints',
        body:
            'Black and white, color pages, page ranges, copies, and A4 options presented clearly for web users.',
      ),
      _ServiceCardData(
        icon: Icons.image_rounded,
        title: 'Image to print',
        body:
            'A clean upload-first path for students and office users who need fast print pickup.',
      ),
      _ServiceCardData(
        icon: Icons.store_mall_directory_rounded,
        title: 'Store discovery',
        body:
            'Show nearby print shops from Firestore shop profiles without relying on paid backend functions.',
      ),
    ];

    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            eyebrow: 'Customer website',
            title: 'Designed for browsers first.',
            body:
                'The web UI focuses on clarity, fast decisions, and large-screen layout instead of bottom tabs and mobile-only controls.',
          ),
          const SizedBox(height: 24),
          wide
              ? Row(
                  children: cards
                      .map(
                        (card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: _ServiceCard(data: card),
                          ),
                        ),
                      )
                      .toList(),
                )
              : Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ServiceCard(data: card),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _StoreSection extends StatelessWidget {
  final bool wide;
  final VoidCallback onStoreLogin;

  const _StoreSection({
    super.key,
    required this.wide,
    required this.onStoreLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E232C),
      child: _PageSection(
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 76),
        child: wide
            ? Row(
                children: [
                  Expanded(child: _StoreCopy(onStoreLogin: onStoreLogin)),
                  const SizedBox(width: 34),
                  const Expanded(child: _StorePreview()),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StoreCopy(onStoreLogin: onStoreLogin),
                  const SizedBox(height: 28),
                  const _StorePreview(),
                ],
              ),
      ),
    );
  }
}

class _QuoteSection extends StatelessWidget {
  final bool wide;
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController locationController;
  final TextEditingController notesController;
  final String service;
  final bool sending;
  final ValueChanged<String?> onServiceChanged;
  final VoidCallback onEmail;
  final VoidCallback onWhatsApp;

  const _QuoteSection({
    super.key,
    required this.wide,
    required this.nameController,
    required this.contactController,
    required this.locationController,
    required this.notesController,
    required this.service,
    required this.sending,
    required this.onServiceChanged,
    required this.onEmail,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    const copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Badge(label: 'Fast request form'),
        SizedBox(height: 18),
        Text(
          'Collect print requests without breaking the free plan.',
          style: TextStyle(
            fontSize: 42,
            height: 1.02,
            letterSpacing: -1.3,
            fontWeight: FontWeight.w900,
            color: ColorPallets.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'This web form uses email or WhatsApp handoff, so you can accept requests now without paying for Cloud Functions. Firestore order sync remains available for signed-in app users.',
          style: TextStyle(
            color: ColorPallets.textSecondary,
            fontSize: 17,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final form = _QuoteForm(
      nameController: nameController,
      contactController: contactController,
      locationController: locationController,
      notesController: notesController,
      service: service,
      sending: sending,
      onServiceChanged: onServiceChanged,
      onEmail: onEmail,
      onWhatsApp: onWhatsApp,
    );

    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 76, 24, 80),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: copy),
                const SizedBox(width: 34),
                Expanded(child: form),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 24), form],
            ),
    );
  }
}

class _QuoteForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController locationController;
  final TextEditingController notesController;
  final String service;
  final bool sending;
  final ValueChanged<String?> onServiceChanged;
  final VoidCallback onEmail;
  final VoidCallback onWhatsApp;

  const _QuoteForm({
    required this.nameController,
    required this.contactController,
    required this.locationController,
    required this.notesController,
    required this.service,
    required this.sending,
    required this.onServiceChanged,
    required this.onEmail,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ColorPallets.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.request_quote_rounded,
                  color: ColorPallets.deepBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print request',
                      style: TextStyle(
                        color: ColorPallets.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Send details in under a minute',
                      style: TextStyle(
                        color: ColorPallets.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contactController,
            decoration: const InputDecoration(labelText: 'Phone or email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(labelText: 'Pickup area'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: service,
            decoration: const InputDecoration(labelText: 'Service'),
            items: const [
              DropdownMenuItem(
                value: 'Black and white documents',
                child: Text('Black and white documents'),
              ),
              DropdownMenuItem(
                value: 'Color documents',
                child: Text('Color documents'),
              ),
              DropdownMenuItem(
                value: 'Assignment binding',
                child: Text('Assignment binding'),
              ),
              DropdownMenuItem(
                value: 'Store partnership',
                child: Text('Store partnership'),
              ),
            ],
            onChanged: onServiceChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Pages, copies, deadline, binding, or color pages',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: sending ? null : onWhatsApp,
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: sending ? null : onEmail,
                  icon: const Icon(Icons.email_rounded),
                  label: const Text('Email'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreCopy extends StatelessWidget {
  final VoidCallback onStoreLogin;

  const _StoreCopy({required this.onStoreLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DarkBadge(label: 'For store owners'),
        const SizedBox(height: 18),
        const Text(
          'A desktop-friendly queue view for print shops.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            height: 1.04,
            letterSpacing: -1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'The website now explains the store workflow clearly: accept, print, ready, collect. It mirrors the Firestore status flow without needing a paid server.',
          style: TextStyle(
            color: Color(0xFFB9C9CF),
            fontSize: 17,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onStoreLogin,
          icon: const Icon(Icons.dashboard_rounded),
          label: const Text('Open store website portal'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ColorPallets.deepBlue,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _StorePreview extends StatelessWidget {
  const _StorePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Today queue',
                style: TextStyle(
                  color: ColorPallets.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Spacer(),
              _StatusPill(label: 'Live'),
            ],
          ),
          const SizedBox(height: 16),
          const _QueueRow(
            order: 'ORD-9182',
            title: 'Lab manual.pdf',
            meta: '68 pages - binding',
            status: 'printing',
            color: ColorPallets.lightBlue,
          ),
          _QueueRow(
            order: 'ORD-9179',
            title: 'ID copies.jpg',
            meta: '4 pages - color',
            status: 'ready',
            color: Colors.green.shade600,
          ),
          _QueueRow(
            order: 'ORD-9171',
            title: 'Assignment.pdf',
            meta: '24 pages - 2 copies',
            status: 'accepted',
            color: Colors.orange.shade700,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_mode_rounded, color: ColorPallets.deepBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Auto-mode can move orders through the queue from the app data.',
                    style: TextStyle(
                      color: ColorPallets.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final String order;
  final String title;
  final String meta;
  final String status;
  final Color color;

  const _QueueRow({
    required this.order,
    required this.title,
    required this.meta,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: ColorPallets.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order,
                  style: const TextStyle(
                    color: ColorPallets.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColorPallets.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  meta,
                  style: const TextStyle(
                    color: ColorPallets.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageSection extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _PageSection({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;

  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: ColorPallets.deepBlue,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: ColorPallets.textPrimary,
              fontSize: 42,
              height: 1.04,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: ColorPallets.textSecondary,
              fontSize: 17,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCardData {
  final IconData icon;
  final String title;
  final String body;

  const _ServiceCardData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceCardData data;

  const _ServiceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ColorPallets.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: ColorPallets.deepBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(data.icon, color: ColorPallets.deepBlue),
          ),
          const SizedBox(height: 22),
          Text(
            data.title,
            style: const TextStyle(
              color: ColorPallets.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.body,
            style: const TextStyle(
              color: ColorPallets.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: ColorPallets.deepBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ColorPallets.deepBlue,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DarkBadge extends StatelessWidget {
  final String label;

  const _DarkBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: ColorPallets.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: ColorPallets.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DarkMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final int step;

  const _ProgressLine({required this.step});

  @override
  Widget build(BuildContext context) {
    const steps = ['Upload', 'Store', 'Print', 'Pickup'];
    return Row(
      children: List.generate(steps.length, (index) {
        final active = index <= step;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: active
                            ? ColorPallets.deepBlue
                            : ColorPallets.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (index != steps.length - 1) const SizedBox(width: 4),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index],
                style: TextStyle(
                  color: active
                      ? ColorPallets.deepBlue
                      : ColorPallets.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StatItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ColorPallets.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: ColorPallets.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WebCustomerAppScreen extends StatefulWidget {
  const WebCustomerAppScreen({super.key});

  @override
  State<WebCustomerAppScreen> createState() => _WebCustomerAppScreenState();
}

class _WebCustomerAppScreenState extends State<WebCustomerAppScreen> {
  StreamSubscription<User?>? _authSub;
  String _customerEmail = '';
  String _customerName = '';
  int _customerTab = 0;
  final _inlineEmailController = TextEditingController();
  final _inlinePasswordController = TextEditingController();
  final _pagesController = TextEditingController(text: '1');
  final _copiesController = TextEditingController(text: '1');
  final _pageRangeController = TextEditingController();
  final _notesController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _ordersSearchController = TextEditingController();
  String _fileName = '';
  String _fileSize = '';
  String _fileDataUrl = '';
  String _fileMimeType = '';
  String _fileStorageUrl = '';
  String _pageDetectLabel = '';
  Uint8List? _fileBytes;
  String _paperSize = 'A4';
  String _sides = 'One side';
  String _color = 'Black and white';
  String _binding = 'No binding';
  String _fulfillmentMode = 'Pickup';
  String _pickupSlot = 'Today, 6 PM - 8 PM';
  bool _payLater = false;
  bool _rushOrder = false;
  bool _inlineLoginLoading = false;
  bool _loadingShops = true;
  bool _placingOrder = false;
  String _placingOrderLabel = '';
  String _ordersStatusFilter = 'all';
  String _ordersSortMode = 'newest';
  Timer? _ordersRefreshTimer;
  StreamSubscription<void>? _orderChangesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _cloudOrderChangesSub;
  List<Shop> _shops = <Shop>[];
  int _selectedShopIndex = 0;
  List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];
  String _lastOrderId = '';
  bool _ordersRefreshing = false;
  bool _ordersRefreshQueued = false;

  @override
  void initState() {
    super.initState();
    _setCustomerFromUser(FirebaseAuth.instance.currentUser, notify: false);
    if (kIsWeb) unawaited(_completeGoogleRedirect());
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      _setCustomerFromUser(user);
      _startCustomerOrderWatch();
      _loadOrders();
    });
    _loadWebAppData();
    _startCustomerOrderWatch();
    _orderChangesSub = DemoOrdersStore.changes.listen((_) {
      _refreshOrdersSoon();
    });
    _ordersRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _customerEmail.isEmpty) return;
      unawaited(_loadOrders());
    });
  }

  Future<void> _completeGoogleRedirect() async {
    try {
      final credential = await FirebaseAuth.instance.getRedirectResult();
      if (credential.user == null) return;
      await _saveCustomerCredential(credential);
      await _loadOrders();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      if (_isMissingRedirectState(error)) return;
      _notifyError('Google sign-in failed', friendlyAuthError(error));
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _inlineEmailController.dispose();
    _inlinePasswordController.dispose();
    _pagesController.dispose();
    _copiesController.dispose();
    _pageRangeController.dispose();
    _notesController.dispose();
    _deliveryAddressController.dispose();
    _ordersSearchController.dispose();
    _ordersRefreshTimer?.cancel();
    _orderChangesSub?.cancel();
    _cloudOrderChangesSub?.cancel();
    super.dispose();
  }

  void _refreshOrdersSoon() {
    if (!mounted || _customerEmail.isEmpty) return;
    unawaited(_loadOrders());
  }

  void _startCustomerOrderWatch() {
    _cloudOrderChangesSub?.cancel();
    _cloudOrderChangesSub = DemoOrdersStore.watchCustomerOrders().listen(
      (_) => _refreshOrdersSoon(),
      onError: (_) {},
    );
  }

  void _setCustomerFromUser(User? user, {bool notify = true}) {
    final nextEmail = user?.email ?? '';
    final nextName = user?.displayName ?? nextEmail.split('@').first;
    if (notify) {
      setState(() {
        _customerEmail = nextEmail;
        _customerName = nextName;
      });
    } else {
      _customerEmail = nextEmail;
      _customerName = nextName;
    }
  }

  Future<void> _submitInlineLogin() async {
    final email = _inlineEmailController.text.trim();
    final password = _inlinePasswordController.text.trim();
    if (email.isEmpty || password.isEmpty || _inlineLoginLoading) return;
    setState(() => _inlineLoginLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveCustomerCredential(credential);
      await _loadOrders();
    } on FirebaseAuthException catch (error) {
      _notifyError('Login failed', friendlyAuthError(error));
    } catch (_) {
      _notifyError('Login failed', 'Login failed. Try again.');
    } finally {
      if (mounted) setState(() => _inlineLoginLoading = false);
    }
  }

  Future<void> _loadWebAppData() async {
    await Future.wait([_loadShops(), _loadOrders()]);
  }

  Future<void> _loadShops() async {
    if (mounted) setState(() => _loadingShops = true);
    var shops = await FirestoreShopService.loadShops();
    if (shops.isEmpty) shops = DemoData.getDefaultShops();
    final registered = _registeredStoresToShops(
      await StoreAuthStore.getRegisteredStores(),
    );
    shops = <Shop>[...shops, ...registered];
    for (final shop in shops) {
      shop.cost = _estimateForShop(shop);
      shop.distance = shop.distance.trim().isEmpty ? 'Nearby' : shop.distance;
      shop.duration =
          shop.duration.trim().isEmpty ? 'Pickup today' : shop.duration;
    }
    if (!mounted) return;
    setState(() {
      _shops = shops;
      if (shops.isEmpty) {
        _selectedShopIndex = 0;
      } else if (_selectedShopIndex >= shops.length) {
        _selectedShopIndex = shops.length - 1;
      }
      _loadingShops = false;
    });
  }

  List<Shop> _registeredStoresToShops(List<Map<String, dynamic>> stores) {
    return stores.map((store) {
      final linkedStoreId =
          (store['linkedStoreId'] ?? store['id'] ?? '').toString();
      final storeName = (store['storeName'] ?? 'Registered Store').toString();
      return Shop(
        id: linkedStoreId,
        name: storeName,
        storeName: storeName,
        address: (store['storeAddress'] ?? '').toString(),
        locationX: ((store['latitude'] as num?) ?? 12.9716).toDouble(),
        locationY: ((store['longitude'] as num?) ?? 77.5946).toDouble(),
        email: (store['email'] ?? '').toString(),
        contactNumber: (store['phoneNumber'] ?? '').toString(),
        openingTime: (store['openingTime'] ?? '').toString(),
        closingTime: (store['closingTime'] ?? '').toString(),
        costOneSide: _priceText(store['costOneSide'], '1.0'),
        costTwoSide: _priceText(store['costTwoSide'], '1.5'),
        costBlack: _priceText(store['costBlack'], '2.0'),
        costColor: _priceText(store['costColor'], '10.0'),
        sizeA4: _priceText(store['sizeA4'], '0.5'),
        sizeA5: _priceText(store['sizeA5'], '0.3'),
        legal: _priceText(store['legal'], '1.0'),
        letter: _priceText(store['letter'], '0.5'),
        spiralBinding: _priceText(store['spiralBinding'], '30.0'),
        staplesBinding: _priceText(store['staplesBinding'], '5.0'),
        stickFile: _priceText(store['stickFile'], '10.0'),
        bondPage: _priceText(store['bondPage'], '5.0'),
        quality100Gsm: _priceText(store['quality100Gsm'], '5.0'),
        quality80gsm: _priceText(store['quality80gsm'], '3.0'),
        avgRating: 4.5,
        distance: 'Registered store',
        duration: 'Pickup at selected time',
      );
    }).toList();
  }

  String _priceText(dynamic value, String fallback) {
    final parsed = double.tryParse((value ?? '').toString().trim());
    if (parsed == null || parsed <= 0) return fallback;
    return parsed.toString();
  }

  Future<void> _loadOrders() async {
    if (_ordersRefreshing) {
      _ordersRefreshQueued = true;
      return;
    }
    _ordersRefreshing = true;
    try {
      do {
        _ordersRefreshQueued = false;
        final orders = await DemoOrdersStore.getOrders();
        if (!mounted) return;
        setState(() => _orders = orders);
      } while (_ordersRefreshQueued && mounted);
    } finally {
      _ordersRefreshing = false;
    }
  }

  Future<bool> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return false;
    final mimeType = _mimeTypeForFile(file.name);
    final bytes = file.bytes;
    final detectedPages = _detectPageCount(mimeType, bytes);
    final dataUrl = bytes == null || bytes.isEmpty
        ? ''
        : 'data:$mimeType;base64,${base64Encode(bytes)}';
    setState(() {
      _fileName = file.name;
      _fileSize = _formatBytes(file.size);
      _fileMimeType = mimeType;
      _fileDataUrl = dataUrl;
      _fileStorageUrl = '';
      _fileBytes = bytes;
      _pageDetectLabel = detectedPages.detected
          ? 'Auto-detected ${detectedPages.pages} page${detectedPages.pages == 1 ? '' : 's'}'
          : 'Could not auto-detect pages. Edit if needed.';
      _pagesController.text = detectedPages.pages.toString();
      if (_copiesController.text.trim().isEmpty) _copiesController.text = '1';
    });
    if (mounted) context.read<AppNotifications>().dismissAll();
    return true;
  }

  ({int pages, bool detected}) _detectPageCount(
    String mimeType,
    Uint8List? bytes,
  ) {
    if (mimeType.startsWith('image/')) return (pages: 1, detected: true);
    if (bytes == null || bytes.isEmpty || mimeType != 'application/pdf') {
      return (pages: 1, detected: false);
    }

    final text = latin1.decode(bytes, allowInvalid: true);
    final pageMatches = RegExp(r'/Type\s*/Page(?!s)\b').allMatches(text).length;
    if (pageMatches > 0) return (pages: pageMatches, detected: true);

    var maxCount = 0;
    for (final match in RegExp(r'/Count\s+(\d+)').allMatches(text)) {
      final count = int.tryParse(match.group(1) ?? '') ?? 0;
      if (count > maxCount) maxCount = count;
    }
    if (maxCount > 0) return (pages: maxCount, detected: true);
    return (pages: 1, detected: false);
  }

  String _mimeTypeForFile(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Selected file';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  int _intValue(TextEditingController controller, int fallback) {
    final value = int.tryParse(controller.text.trim()) ?? fallback;
    return value < 1 ? fallback : value;
  }

  int get _copies => _intValue(_copiesController, 1);

  int get _totalPages => _intValue(_pagesController, 1);

  PdfData _buildPdfData({String? documentUrl}) {
    final document = (documentUrl ?? '').trim().isNotEmpty
        ? documentUrl!.trim()
        : (_fileStorageUrl.isNotEmpty
            ? _fileStorageUrl
            : (_fileDataUrl.isNotEmpty
                ? _fileDataUrl
                : (_fileName.isEmpty ? 'web_upload_pending' : _fileName)));
    return PdfData(
      name: _fileName.isEmpty ? 'Website upload' : _fileName,
      size: _fileSize.isEmpty ? 'Web file' : _fileSize,
      totalPages: _totalPages,
      copies: _copies,
      binding: _binding,
      paperSize: _paperSize,
      pdfSides: _sides,
      pdfPrintLayout: 'Portrait',
      color: _color,
      pageRange: _pageRangeController.text.trim(),
      colorParDesciption: '',
      colorParPageNumbers: '',
      colorParTotal: _color == 'Color' ? _totalPages : 0,
      additionDesciption: [
        _notesController.text.trim(),
        if (_fileMimeType.isNotEmpty) 'mimeType=$_fileMimeType',
      ].where((part) => part.isNotEmpty).join('\n'),
      documents: document,
      bondPages: false,
    );
  }

  double _estimateForShop(Shop shop) {
    final pdf = _buildPdfData();
    final rateText = _color == 'Color' ? shop.costColor : shop.costBlack;
    final fallbackRate = _color == 'Color' ? 10.0 : 2.0;
    final parsedRate = double.tryParse(rateText);
    final pageRate =
        parsedRate == null || parsedRate <= 0 ? fallbackRate : parsedRate;
    var total = pdf.selectedPagesCount * _copies * pageRate;
    if (_sides == 'Both sides') total *= 0.85;
    total += switch (_binding) {
      'Spiral binding' => _positivePrice(shop.spiralBinding, 30.0),
      'Staples' => _positivePrice(shop.staplesBinding, 5.0),
      'Stick file' => _positivePrice(shop.stickFile, 10.0),
      _ => 0.0,
    };
    if (_rushOrder) total += 20;
    return total;
  }

  double _positivePrice(String value, double fallback) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }

  double _displayOrderTotal(Map<String, dynamic> order) {
    final saved = double.tryParse((order['totalCost'] ?? 0).toString()) ?? 0;
    if (saved > 0) return saved;
    final items = (order['items'] as List?) ?? const <dynamic>[];
    var total = 0.0;
    for (final item in items) {
      final map = item is Map ? Map<String, dynamic>.from(item) : const {};
      final itemCost = double.tryParse((map['itemCost'] ?? 0).toString()) ?? 0;
      if (itemCost > 0) {
        total += itemCost;
        continue;
      }
      final pages = int.tryParse((map['totalPages'] ?? 1).toString()) ?? 1;
      final copies = int.tryParse((map['copies'] ?? 1).toString()) ?? 1;
      final color = (map['itemColor'] ?? '').toString().toLowerCase();
      final rate = color.contains('color') ? 10.0 : 2.0;
      total += pages * copies * rate;
    }
    return total;
  }

  Shop? get _selectedShop {
    if (_shops.isEmpty) return null;
    final index = _selectedShopIndex >= _shops.length
        ? _shops.length - 1
        : _selectedShopIndex;
    return _shops[index < 0 ? 0 : index];
  }

  double get _currentEstimate {
    final shop = _selectedShop;
    return shop == null
        ? _estimateForShop(DemoData.getDefaultShops().first)
        : _estimateForShop(shop);
  }

  Map<String, dynamic>? get _lastOrder {
    if (_lastOrderId.isEmpty) return null;
    for (final order in _orders) {
      if ((order['orderId'] ?? '').toString() == _lastOrderId) return order;
    }
    return null;
  }

  String _customerOrderStatus(Map<String, dynamic> order) {
    final status =
        (order['status'] ?? 'pending').toString().trim().toLowerCase();
    if (status == 'completed') return 'collected';
    if (status == 'in_printing' || status == 'inprinting') return 'printing';
    return status.isEmpty ? 'pending' : status;
  }

  int get _activeCustomerOrderCount => _orders.where((order) {
        final status = _customerOrderStatus(order);
        return status != 'collected' &&
            status != 'rejected' &&
            status != 'failed';
      }).length;

  int get _todayCustomerOrderCount {
    final now = DateTime.now();
    return _orders.where((order) {
      final createdAt =
          DateTime.tryParse((order['orderDate'] ?? '').toString());
      return createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;
  }

  double get _customerTotalSpend {
    return _orders.fold<double>(0, (total, order) {
      return total + _displayOrderTotal(order);
    });
  }

  List<Map<String, dynamic>> get _visibleCustomerOrders {
    final query = _ordersSearchController.text.trim().toLowerCase();
    final output = _orders
        .where((order) {
          final status = _customerOrderStatus(order);
          if (_ordersStatusFilter != 'all' && status != _ordersStatusFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          final searchable = [
            order['orderId'],
            order['storeName'],
            order['storeAddress'],
            order['paymentStatus'],
            order['fulfillmentMode'],
            order['items'],
          ].join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .map((order) => Map<String, dynamic>.from(order))
        .toList();

    output.sort((a, b) {
      final aDate = DateTime.tryParse((a['orderDate'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse((b['orderDate'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final aCost = double.tryParse((a['totalCost'] ?? 0).toString()) ?? 0;
      final bCost = double.tryParse((b['totalCost'] ?? 0).toString()) ?? 0;
      return switch (_ordersSortMode) {
        'oldest' => aDate.compareTo(bDate),
        'amount_high' => bCost.compareTo(aCost),
        'amount_low' => aCost.compareTo(bCost),
        'status' => _customerOrderStatus(a).compareTo(_customerOrderStatus(b)),
        _ => bDate.compareTo(aDate),
      };
    });
    return output;
  }

  void _goToStep(int step) {
    setState(() {
      if (step < -1) {
        _customerTab = -1;
      } else if (step > 6) {
        _customerTab = 6;
      } else {
        _customerTab = step;
      }
    });
  }

  void _nextFromUpload() {
    if (_fileName.isEmpty) {
      _notifyError('Choose a file', 'Upload a PDF or image to continue.');
      return;
    }
    _goToStep(1);
  }

  void _nextFromStores() {
    if (_selectedShop == null) {
      _notifyError('Choose a store', 'Select a print store to continue.');
      return;
    }
    _goToStep(3);
  }

  void _startNewOrder() {
    setState(() {
      _customerTab = 0;
      _fileName = '';
      _fileSize = '';
      _fileDataUrl = '';
      _fileMimeType = '';
      _fileStorageUrl = '';
      _pageDetectLabel = '';
      _fileBytes = null;
      _pagesController.text = '1';
      _copiesController.text = '1';
      _pageRangeController.clear();
      _notesController.clear();
      _deliveryAddressController.clear();
      _paperSize = 'A4';
      _sides = 'One side';
      _color = 'Black and white';
      _binding = 'No binding';
      _fulfillmentMode = 'Pickup';
      _pickupSlot = 'Today, 6 PM - 8 PM';
      _payLater = false;
      _rushOrder = false;
      _lastOrderId = '';
    });
  }

  void _reorderLatestOrder() {
    if (_orders.isEmpty) {
      _goToStep(5);
      return;
    }
    _reorderFromOrder(_orders.first);
  }

  void _reorderFromOrder(Map<String, dynamic> order) {
    final items = (order['items'] as List?) ?? const <dynamic>[];
    final first = items.isNotEmpty && items.first is Map
        ? Map<String, dynamic>.from(items.first as Map)
        : <String, dynamic>{};
    final storeId = (order['storeId'] ?? '').toString();
    var selectedIndex = _selectedShopIndex;
    final matchIndex = _shops.indexWhere((shop) => shop.id == storeId);
    if (matchIndex >= 0) selectedIndex = matchIndex;
    final rawSide = (first['side'] ?? '').toString().toLowerCase();
    final rawColor = (first['itemColor'] ?? '').toString().toLowerCase();

    setState(() {
      _customerTab = 1;
      _fileName = _fileNameFromOrderItem(first);
      _fileSize = 'Saved order';
      _fileDataUrl = '';
      _fileMimeType = (first['mimeType'] ?? '').toString();
      _fileStorageUrl =
          (first['downloadUrl'] ?? first['documents'] ?? '').toString().trim();
      _pageDetectLabel = 'Loaded from previous order';
      _fileBytes = null;
      _pagesController.text = (first['totalPages'] ?? 1).toString();
      _copiesController.text = (first['copies'] ?? 1).toString();
      _pageRangeController.text = (first['pageRange'] ?? '').toString();
      _notesController.text = (first['notes'] ?? '').toString();
      _paperSize = (first['paperSize'] ?? 'A4').toString();
      _sides = rawSide.contains('both') || rawSide.contains('double')
          ? 'Both sides'
          : 'One side';
      _color = rawColor.contains('color') && !rawColor.contains('black')
          ? 'Color'
          : 'Black and white';
      _binding = (first['binding'] ?? 'No binding').toString();
      _fulfillmentMode = (order['fulfillmentMode'] ?? 'Pickup').toString();
      _pickupSlot = (order['pickupSlot'] ?? 'Today, 6 PM - 8 PM').toString();
      _deliveryAddressController.text =
          (order['deliveryAddress'] ?? '').toString();
      _payLater = order['orderLater'] == true;
      _rushOrder = order['rushOrder'] == true;
      _selectedShopIndex = selectedIndex;
      _lastOrderId = '';
    });
    _notifySuccess('Reorder ready', 'Review settings and choose checkout.');
  }

  String _fileNameFromOrderItem(Map<String, dynamic> item) {
    final explicit = (item['fileName'] ?? item['name'] ?? '').toString().trim();
    if (explicit.isNotEmpty) return explicit;
    final raw = (item['downloadUrl'] ?? item['documents'] ?? '').toString();
    if (raw.startsWith('data:')) return 'Uploaded document';
    if (raw.trim().isEmpty) return 'Document';
    return raw;
  }

  Future<void> _startUploadFromHome() async {
    _startNewOrder();
    final picked = await _pickFile();
    if (!mounted) return;
    if (picked) _goToStep(1);
  }

  Future<String> _printableDocumentUrlForOrder(String orderId) async {
    if (_fileStorageUrl.trim().isNotEmpty) return _fileStorageUrl.trim();
    if (_fileDataUrl.isNotEmpty && _fileDataUrl.length < 850000) {
      return _fileDataUrl;
    }
    if (_fileBytes == null || _fileBytes!.isEmpty) {
      if (_fileDataUrl.isNotEmpty) return _fileDataUrl;
      throw StateError('The selected file is not available for upload.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Login again before uploading the printable file.');
    }

    if (_fileDataUrl.length > 6000000) {
      throw StateError(
        'Free mode supports printable files up to about 4 MB. Compress this file or upload fewer pages.',
      );
    }

    try {
      final chunkCount = await _savePrintableFileChunks(
        orderId: orderId,
        userId: uid,
        dataUrl: _fileDataUrl,
      ).timeout(const Duration(seconds: 20));
      return 'firestore_chunks:$orderId:$chunkCount';
    } on TimeoutException {
      throw StateError(
        'Saving the file took too long. Try a smaller file or check your network.',
      );
    } catch (_) {
      throw StateError(
        'Could not save the printable file in free mode. Try a smaller PDF/image.',
      );
    }
  }

  Future<int> _savePrintableFileChunks({
    required String orderId,
    required String userId,
    required String dataUrl,
  }) async {
    const chunkSize = 450000;
    final chunks = <String>[];
    for (var start = 0; start < dataUrl.length; start += chunkSize) {
      final end = start + chunkSize > dataUrl.length
          ? dataUrl.length
          : start + chunkSize;
      chunks.add(dataUrl.substring(start, end));
    }
    if (chunks.isEmpty) throw StateError('No printable file data found.');

    final db = FirebaseFirestore.instance;
    final collection =
        db.collection('orders_demo').doc(orderId).collection('file_chunks');

    for (var start = 0; start < chunks.length; start += 400) {
      final batch = db.batch();
      final end = start + 400 > chunks.length ? chunks.length : start + 400;
      for (var i = start; i < end; i++) {
        batch.set(collection.doc(i.toString().padLeft(4, '0')), {
          'index': i,
          'data': chunks[i],
          'orderId': orderId,
          'userId': userId,
          'fileName': _fileName,
          'mimeType': _fileMimeType,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    }
    return chunks.length;
  }

  Future<void> _placeOrder() async {
    if (_customerEmail.isEmpty) {
      _notifyError('Login required', 'Login to place a website app order.');
      return;
    }
    if (_fileName.isEmpty) {
      _notifyError('Choose a file', 'Upload a PDF or image before checkout.');
      setState(() => _customerTab = 0);
      return;
    }
    final shop = _selectedShop;
    if (shop == null) {
      _notifyError('No store selected', 'Choose a print store first.');
      setState(() => _customerTab = 2);
      return;
    }
    setState(() {
      _placingOrder = true;
      _placingOrderLabel = 'Saving printable file...';
    });
    try {
      shop.cost = _estimateForShop(shop);
      final orderId = DemoOrdersStore.createOrderId();
      final printableDocumentUrl = await _printableDocumentUrlForOrder(orderId);
      if (mounted) {
        setState(() => _placingOrderLabel = 'Creating order...');
      }
      final createdOrderId = await DemoOrdersStore.addOrder(
        shop: shop,
        pdfs: [_buildPdfData(documentUrl: printableDocumentUrl)],
        payLater: _payLater,
        orderId: orderId,
        fulfillmentMode: _fulfillmentMode,
        pickupSlot: _pickupSlot,
        rushOrder: _rushOrder,
        deliveryAddress: _fulfillmentMode == 'Delivery'
            ? _deliveryAddressController.text.trim()
            : '',
        defaultPaymentMethod: _payLater ? 'PayLater' : 'Pay at pickup',
      );
      await _loadOrders();
      if (!mounted) return;
      setState(() {
        _lastOrderId = createdOrderId;
        _customerTab = 4;
      });
      _notifySuccess(
          'Order confirmed', 'Website order $createdOrderId is in your app.');
    } catch (error) {
      _notifyError(
        'Order failed',
        error is StateError
            ? error.message
            : 'Could not place this web app order.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
          _placingOrderLabel = '';
        });
      }
    }
  }

  void _notifySuccess(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addSuccess(title: title, body: body);
  }

  void _notifyWarning(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addWarning(title: title, body: body);
  }

  void _notifyError(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addError(title: title, body: body);
  }

  Future<void> _saveCustomerCredential(UserCredential credential) async {
    final user = credential.user;
    final token = await user?.getIdToken(true);
    if (token != null && token.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('AccessToken', token);
    }
    _setCustomerFromUser(user);
    if (user != null && !user.emailVerified) {
      _notifyWarning(
        'Verify your email',
        'Signed in as ${user.email ?? 'your account'}. Check your inbox to verify and secure it.',
      );
    } else {
      _notifySuccess(
        'App dashboard opened',
        'Signed in as ${user?.email ?? 'Dittox user'}.',
      );
    }
  }

  Future<void> _showCustomerLogin() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit() async {
            final email = emailController.text.trim();
            final password = passwordController.text.trim();
            if (email.isEmpty || password.isEmpty || loading) return;
            setDialogState(() => loading = true);
            var dialogClosed = false;
            try {
              final credential =
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              await _saveCustomerCredential(credential);
              if (!dialogContext.mounted) return;
              dialogClosed = true;
              Navigator.of(dialogContext).pop();
            } on FirebaseAuthException catch (error) {
              if (!mounted) return;
              _notifyError('Login failed', friendlyAuthError(error));
            } catch (_) {
              if (!mounted) return;
              _notifyError('Login failed', 'Login failed. Try again.');
            } finally {
              if (mounted && !dialogClosed) {
                setDialogState(() => loading = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Customer App Login'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Login to open your full Dittox web app dashboard.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              Navigator.of(dialogContext).pop();
                              await _signInWithGoogle();
                            },
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    loading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: loading ? null : submit,
                child: Text(loading ? 'Signing in...' : 'Login'),
              ),
            ],
          );
        },
      ),
    );

    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final credential = await _signInWithGoogleCredential();
      if (credential == null) return;
      await _saveCustomerCredential(credential);
    } on FirebaseAuthException catch (error) {
      _notifyError('Google sign-in failed', friendlyAuthError(error));
    } catch (_) {
      _notifyError(
        'Google sign-in failed',
        'Could not complete Google sign-in.',
      );
    }
  }

  Future<void> _goHome() async {
    await launchUrl(Uri.base.resolve('/'), webOnlyWindowName: '_self');
  }

  Future<void> _goToStoreWebsite() async {
    await launchUrl(Uri.base.resolve('/store'), webOnlyWindowName: '_self');
  }

  Future<void> _logoutCustomer() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('AccessToken');
    if (!mounted) return;
    setState(() {
      _customerEmail = '';
      _customerName = '';
      _customerTab = -1;
      _orders = <Map<String, dynamic>>[];
    });
    _notifySuccess('Logged out', 'Customer web app session closed.');
  }

  Widget _buildLoginGate() {
    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 54, 24, 78),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: ColorPallets.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final copy = Container(
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D3537), Color(0xFF102A56)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(34),
                  bottomLeft: Radius.circular(34),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DarkBadge(label: 'Customer website app'),
                  SizedBox(height: 22),
                  Text(
                    'Login first. Then the actual web app opens here.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 0.98,
                      letterSpacing: -1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This is not a contact form or prototype. It opens the customer order workflow inside the website: upload, settings, stores, checkout, orders, and wallet.',
                    style: TextStyle(
                      color: Color(0xFFD7E5EA),
                      fontSize: 16,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
            final form = Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Customer login',
                    style: TextStyle(
                      color: ColorPallets.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Use Firebase email login or Google to open the website app.',
                    style: TextStyle(
                      color: ColorPallets.textSecondary,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _inlineEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onSubmitted: (_) => _submitInlineLogin(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _inlinePasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => _submitInlineLogin(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _inlineLoginLoading ? null : _submitInlineLogin,
                    icon: const Icon(Icons.login_rounded),
                    label: Text(_inlineLoginLoading
                        ? 'Opening app...'
                        : 'Login and open app'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorPallets.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _inlineLoginLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPallets.deepBlue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: copy),
                      Expanded(child: form),
                    ],
                  )
                : Column(children: [copy, form]);
          },
        ),
      ),
    );
  }

  Widget _buildWebAppDashboard(double width, String userLabel) {
    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 42, 24, 74),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Print from web, like the app.',
            style: TextStyle(
              color: ColorPallets.textPrimary,
              fontSize: 50,
              height: 1,
              letterSpacing: -1.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back, $userLabel. Same Dittox flow, rebuilt for a browser layout instead of a stretched phone screen.',
            style: const TextStyle(
              color: ColorPallets.textSecondary,
              fontSize: 17,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          if (_customerTab == -1) ...[
            _buildCustomerCommandPanel(),
          ] else ...[
            _buildAppContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCommandPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final todayCard = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D3537), Color(0xFF4DA6A9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: ColorPallets.deepBlue.withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Today\'s Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildWebStatTile(
                      _todayCustomerOrderCount.toString(), 'Orders'),
                  const SizedBox(width: 10),
                  _buildWebStatTile(
                    'Rs ${_customerTotalSpend.toStringAsFixed(0)}',
                    'Spent',
                  ),
                  const SizedBox(width: 10),
                  _buildWebStatTile(
                    _activeCustomerOrderCount.toString(),
                    'Active',
                  ),
                ],
              ),
            ],
          ),
        );

        final inviteCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8EF), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ColorPallets.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Image.asset(
                  'assets/image/referFriend.png',
                  height: narrow ? 128 : 190,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6D2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'DITTOX PRO BONUS',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Invite your friend',
                      style: TextStyle(
                        color: ColorPallets.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Get reward up to Rs 50',
                      style: TextStyle(
                        color: ColorPallets.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => _goToStep(6),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorPallets.deepBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Invite now'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        final quickActions = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ColorPallets.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: ColorPallets.deepBlue),
                  SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: ColorPallets.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Upload or scan and place your print order instantly.',
                style: TextStyle(
                  color: ColorPallets.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildWebQuickActionCard(
                image: 'assets/image/documentUpload.png',
                title: 'Upload Document',
                subtitle: 'PDF, JPG, PNG',
                onTap: () => unawaited(_startUploadFromHome()),
              ),
              const SizedBox(height: 12),
              _buildWebQuickActionCard(
                image: 'assets/image/ImageUpload2.png',
                title: 'Scan Document',
                subtitle: 'Pick image files on web',
                onTap: () => unawaited(_startUploadFromHome()),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildWebShortcut(Icons.replay_rounded, 'Reorder', () {
                    _reorderLatestOrder();
                  }),
                  _buildWebShortcut(Icons.favorite_rounded, 'Favorite stores',
                      () {
                    _goToStep(2);
                  }),
                  _buildWebShortcut(Icons.support_agent_rounded, 'Help', () {
                    _goToStep(6);
                  }),
                  _buildWebShortcut(Icons.storefront_rounded, 'Become a store',
                      () {
                    _goToStoreWebsite();
                  }),
                ],
              ),
            ],
          ),
        );

        if (narrow) {
          return Column(
            children: [
              todayCard,
              const SizedBox(height: 14),
              inviteCard,
              const SizedBox(height: 14),
              quickActions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  todayCard,
                  const SizedBox(height: 14),
                  inviteCard,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: quickActions),
          ],
        );
      },
    );
  }

  Widget _buildWebStatTile(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebQuickActionCard({
    required String image,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ColorPallets.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 88,
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ColorPallets.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ColorPallets.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE9DDE7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: ColorPallets.deepBlue, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebShortcut(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: ColorPallets.deepBlue),
      label: Text(label),
      backgroundColor: const Color(0xFFF3F7F8),
      labelStyle: const TextStyle(
        color: ColorPallets.deepBlue,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildAppContent() {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          switch (_customerTab) {
            0 => _buildUploadTab(),
            1 => _buildPrintSettingsTab(),
            2 => _buildStoresTab(),
            3 => _buildCheckoutTab(),
            4 => _buildConfirmationTab(),
            5 => _buildOrdersTab(),
            _ => _buildCustomerProfileTab(),
          },
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          eyebrow: 'Step 1',
          title: 'Upload your document.',
          body:
              'Start the real website app order flow by choosing the PDF or image you want printed.',
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F8),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: ColorPallets.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.upload_file_rounded,
                      color: ColorPallets.deepBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName.isEmpty ? 'Choose PDF or image' : _fileName,
                        style: const TextStyle(
                          color: ColorPallets.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fileName.isEmpty
                            ? 'PDF, JPG, JPEG, or PNG'
                            : [
                                _fileSize,
                                if (_pageDetectLabel.isNotEmpty)
                                  _pageDetectLabel,
                              ].join(' - '),
                        style: const TextStyle(
                          color: ColorPallets.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: ColorPallets.deepBlue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 700;
            final fields = [
              TextField(
                controller: _pagesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total pages',
                  helperText: _pageDetectLabel.isEmpty
                      ? 'Defaults to 1 until a file is selected'
                      : _pageDetectLabel,
                ),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: _copiesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Copies',
                  helperText: 'Default: 1 copy',
                ),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                controller: _pageRangeController,
                decoration:
                    const InputDecoration(labelText: 'Page range (optional)'),
                onChanged: (_) => setState(() {}),
              ),
            ];
            return narrow
                ? Column(
                    children: fields
                        .map((field) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: field,
                            ))
                        .toList(),
                  )
                : Row(
                    children: fields
                        .map((field) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: field,
                              ),
                            ))
                        .toList(),
                  );
          },
        ),
        const SizedBox(height: 22),
        _buildStepActions(
          primaryLabel: 'Next: Print settings',
          onPrimary: _nextFromUpload,
        ),
      ],
    );
  }

  Widget _buildPrintSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          eyebrow: 'Step 2',
          title: 'Choose print settings.',
          body:
              'Set paper, sides, color, binding, and special instructions before choosing the store.',
        ),
        const SizedBox(height: 18),
        _buildSettingGrid(),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Print notes',
            hintText: 'Example: print first page color, bind left side...',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        _buildOrderSummaryStrip(),
        const SizedBox(height: 22),
        _buildStepActions(
          secondaryLabel: 'Back to upload',
          onSecondary: () => _goToStep(0),
          primaryLabel: 'Next: Choose store',
          onPrimary: () => _goToStep(2),
        ),
      ],
    );
  }

  Widget _buildSettingGrid() {
    final dropdowns = [
      DropdownButtonFormField<String>(
        initialValue: _paperSize,
        decoration: const InputDecoration(labelText: 'Paper'),
        items: const ['A4', 'A5', 'Legal', 'Letter']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _paperSize = value ?? _paperSize),
      ),
      DropdownButtonFormField<String>(
        initialValue: _sides,
        decoration: const InputDecoration(labelText: 'Sides'),
        items: const ['One side', 'Both sides']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _sides = value ?? _sides),
      ),
      DropdownButtonFormField<String>(
        initialValue: _color,
        decoration: const InputDecoration(labelText: 'Color'),
        items: const ['Black and white', 'Color']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _color = value ?? _color),
      ),
      DropdownButtonFormField<String>(
        initialValue: _binding,
        decoration: const InputDecoration(labelText: 'Binding'),
        items: const ['No binding', 'Staples', 'Spiral binding', 'Stick file']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (value) => setState(() => _binding = value ?? _binding),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 700 ? 1 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 6.2 : 5.1,
          children: dropdowns,
        );
      },
    );
  }

  Widget _buildOrderSummaryStrip() {
    final shop = _selectedShop;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatusPill(label: _fileName.isEmpty ? 'No file' : _fileName),
          _StatusPill(label: '$_totalPages pages'),
          _StatusPill(label: '$_copies copy${_copies == 1 ? '' : 'ies'}'),
          _StatusPill(label: _paperSize),
          _StatusPill(label: _sides),
          _StatusPill(label: _color),
          _StatusPill(label: _binding),
          if (shop != null)
            _StatusPill(
              label: shop.storeName.isNotEmpty ? shop.storeName : shop.name,
            ),
          _StatusPill(label: 'Rs ${_currentEstimate.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildStepActions({
    String? secondaryLabel,
    VoidCallback? onSecondary,
    required String primaryLabel,
    VoidCallback? onPrimary,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        if (secondaryLabel != null)
          OutlinedButton.icon(
            onPressed: onSecondary,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(secondaryLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorPallets.deepBlue,
              side: const BorderSide(color: ColorPallets.deepBlue),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        FilledButton.icon(
          onPressed: onPrimary,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(primaryLabel),
          style: FilledButton.styleFrom(
            backgroundColor: ColorPallets.deepBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStoresTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                eyebrow: 'Step 3',
                title: 'Choose the print store.',
                body:
                    'Real Firestore shop profiles load here, with fallback stores if Firestore is empty.',
              ),
            ),
            IconButton(
              onPressed: _loadShops,
              tooltip: 'Refresh stores',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingShops)
          const Center(child: CircularProgressIndicator())
        else
          ...List.generate(_shops.length, (index) {
            final shop = _shops[index];
            final selected = index == _selectedShopIndex;
            final estimate = _estimateForShop(shop);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedShopIndex = index),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFF0FAFA) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? ColorPallets.deepBlue
                          : ColorPallets.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: ColorPallets.deepBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.storeName.isNotEmpty
                                  ? shop.storeName
                                  : shop.name,
                              style: const TextStyle(
                                color: ColorPallets.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              shop.address.isEmpty
                                  ? shop.distance
                                  : shop.address,
                              style: const TextStyle(
                                color: ColorPallets.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs ${estimate.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: ColorPallets.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${shop.avgRating.toStringAsFixed(1)} rating',
                            style: const TextStyle(
                              color: ColorPallets.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 18),
        _buildStepActions(
          secondaryLabel: 'Back to settings',
          onSecondary: () => _goToStep(1),
          primaryLabel: 'Next: Checkout',
          onPrimary: _nextFromStores,
        ),
      ],
    );
  }

  Widget _buildCheckoutTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          eyebrow: 'Step 4',
          title: 'Checkout and payment choice.',
          body:
              'Review the order, choose pickup or delivery, then confirm. This creates the order and takes you to confirmation.',
        ),
        const SizedBox(height: 18),
        _buildCheckoutPanel(),
        const SizedBox(height: 18),
        _buildStepActions(
          secondaryLabel: 'Back to stores',
          onSecondary: () => _goToStep(2),
          primaryLabel: _placingOrder
              ? (_placingOrderLabel.isEmpty
                  ? 'Placing order...'
                  : _placingOrderLabel)
              : 'Confirm order',
          onPrimary: _placingOrder ? null : _placeOrder,
        ),
      ],
    );
  }

  Widget _buildConfirmationTab() {
    if (_lastOrderId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            eyebrow: 'Step 5',
            title: 'Order confirmation appears after checkout.',
            body:
                'Confirm the checkout first. Then this page shows order ID, store, status, and total before moving to the orders page.',
          ),
          const SizedBox(height: 22),
          _buildStepActions(
            secondaryLabel: 'Back to checkout',
            onSecondary: () => _goToStep(3),
            primaryLabel: 'Go to orders page',
            onPrimary: () => _goToStep(5),
          ),
        ],
      );
    }
    final order = _lastOrder;
    final id = _lastOrderId;
    final store =
        (order?['storeName'] ?? _selectedShop?.storeName ?? 'Dittox Store')
            .toString();
    final total =
        double.tryParse((order?['totalCost'] ?? _currentEstimate).toString()) ??
            _currentEstimate;
    final status =
        (order?['status'] ?? (_payLater ? 'pending' : 'accepted')).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D3537), Color(0xFF102A56)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 18),
              const Text(
                'Order confirmed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  height: 1,
                  letterSpacing: -1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your website app order is now visible in the Dittox orders page and store workflow.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildConfirmationRow('Order ID', id),
        _buildConfirmationRow('Store', store),
        _buildConfirmationRow('Status', status),
        _buildConfirmationRow('Total', 'Rs ${total.toStringAsFixed(0)}'),
        const SizedBox(height: 22),
        _buildStepActions(
          secondaryLabel: 'New order',
          onSecondary: _startNewOrder,
          primaryLabel: 'Next: Orders page',
          onPrimary: () => _goToStep(5),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: ColorPallets.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: ColorPallets.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    final orders = _visibleCustomerOrders.take(24).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                eyebrow: 'Orders page',
                title: 'All website app orders.',
                body:
                    'Orders created here are saved into the same order store used by customer and store screens.',
              ),
            ),
            IconButton(
              onPressed: _loadOrders,
              tooltip: 'Refresh orders',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCustomerOrderFilters(),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'No orders yet. Upload a file and place the first website app order.',
              style: TextStyle(
                color: ColorPallets.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          ...orders.map(_buildCustomerOrderCard),
        const SizedBox(height: 18),
        _buildStepActions(
          primaryLabel: 'Start new order',
          onPrimary: _startNewOrder,
        ),
      ],
    );
  }

  Widget _buildCustomerOrderFilters() {
    const statuses = [
      'all',
      'pending',
      'accepted',
      'printing',
      'ready',
      'rejected',
      'collected'
    ];
    const sortModes = [
      'newest',
      'oldest',
      'status',
      'amount_high',
      'amount_low'
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;
        final controls = [
          TextField(
            controller: _ordersSearchController,
            decoration: const InputDecoration(
              labelText: 'Search orders',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          DropdownButtonFormField<String>(
            initialValue: _ordersStatusFilter,
            decoration: const InputDecoration(labelText: 'Status'),
            items: statuses
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status == 'all' ? 'All statuses' : status),
                    ))
                .toList(),
            onChanged: (value) => setState(
              () => _ordersStatusFilter = value ?? _ordersStatusFilter,
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _ordersSortMode,
            decoration: const InputDecoration(labelText: 'Sort'),
            items: sortModes
                .map((mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(switch (mode) {
                        'oldest' => 'Oldest first',
                        'status' => 'Status',
                        'amount_high' => 'Amount high',
                        'amount_low' => 'Amount low',
                        _ => 'Newest first',
                      }),
                    ))
                .toList(),
            onChanged: (value) => setState(
              () => _ordersSortMode = value ?? _ordersSortMode,
            ),
          ),
        ];
        return narrow
            ? Column(
                children: controls
                    .map((control) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: control,
                        ))
                    .toList(),
              )
            : Row(
                children: controls
                    .map((control) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: control,
                          ),
                        ))
                    .toList(),
              );
      },
    );
  }

  Widget _buildCustomerOrderCard(Map<String, dynamic> order) {
    final id = (order['orderId'] ?? '').toString();
    final store = (order['storeName'] ?? 'Dittox Store').toString();
    final status = _customerOrderStatus(order);
    final total = _displayOrderTotal(order);
    final pages = (order['totalPages'] ?? 0).toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColorPallets.cardBorder),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 680;
            final title = Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: ColorPallets.deepBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id.isEmpty ? 'Website order' : id,
                        style: const TextStyle(
                          color: ColorPallets.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$store - $pages pages - Rs ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: ColorPallets.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                _StatusPill(label: status),
                TextButton.icon(
                  onPressed: () => _reorderFromOrder(order),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Reorder'),
                ),
                TextButton.icon(
                  onPressed: () => _showCustomerOrderDetails(order),
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('Details'),
                ),
                if (status == 'pending' || status == 'accepted')
                  TextButton.icon(
                    onPressed: () => _cancelCustomerOrder(order),
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            );
            return narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 14), actions],
                  )
                : Row(children: [Expanded(child: title), actions]);
          },
        ),
      ),
    );
  }

  Future<void> _cancelCustomerOrder(Map<String, dynamic> order) async {
    final orderId = (order['orderId'] ?? '').toString();
    if (orderId.isEmpty) return;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order'),
        content: TextField(
          controller: reasonController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Example: uploaded wrong file',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              reasonController.text.trim(),
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    final ok = await DemoOrdersStore.updateOrderStatus(
      orderId: orderId,
      status: 'rejected',
      cancelReason: reason,
    );
    await _loadOrders();
    if (!mounted) return;
    if (ok) {
      _notifySuccess('Order cancelled', '$orderId was cancelled.');
    } else {
      _notifyError('Cancel failed', 'Could not cancel $orderId.');
    }
  }

  Future<void> _showCustomerOrderDetails(Map<String, dynamic> order) async {
    final items = (order['items'] as List?) ?? const <dynamic>[];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text((order['orderId'] ?? 'Order details').toString()),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _customerDetailLine('Status', _customerOrderStatus(order)),
                _customerDetailLine(
                  'Store',
                  (order['storeName'] ?? 'Dittox Store').toString(),
                ),
                _customerDetailLine(
                  'Total',
                  'Rs ${_displayOrderTotal(order).toStringAsFixed(0)}',
                ),
                _customerDetailLine(
                  'Fulfillment',
                  (order['fulfillmentMode'] ?? 'Pickup').toString(),
                ),
                _customerDetailLine(
                  'Payment',
                  (order['paymentStatus'] ?? '').toString(),
                ),
                const SizedBox(height: 12),
                const Text('Documents',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text('No document details saved.')
                else
                  ...items.map((item) {
                    final map = item is Map
                        ? Map<String, dynamic>.from(item)
                        : <String, dynamic>{};
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${_fileNameFromOrderItem(map)} - ${map['totalPages'] ?? '-'} pages - ${map['copies'] ?? 1} copies - ${map['binding'] ?? 'No binding'}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _customerDetailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: ColorPallets.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerProfileTab() {
    final user = FirebaseAuth.instance.currentUser;
    final rows = [
      ('Name', _customerName.isEmpty ? 'Dittox user' : _customerName),
      ('Email', _customerEmail),
      ('Firebase UID', user?.uid ?? '-'),
      ('Active orders', _activeCustomerOrderCount.toString()),
      ('Total orders', _orders.length.toString()),
      ('Total spend', 'Rs ${_customerTotalSpend.toStringAsFixed(0)}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          eyebrow: 'Profile',
          title: 'Customer account.',
          body:
              'Browser version of the app profile with account details, order totals, and quick actions for the web flow.',
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7F8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ColorPallets.cardBorder),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final avatar = Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D3537), Color(0xFF102A56)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 42),
              );
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customerName.isEmpty ? 'Dittox user' : _customerName,
                    style: const TextStyle(
                      color: ColorPallets.textPrimary,
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _customerEmail,
                    style: const TextStyle(
                      color: ColorPallets.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatusPill(label: '${_orders.length} orders'),
                      _StatusPill(label: '$_activeCustomerOrderCount active'),
                      _StatusPill(
                        label:
                            'Rs ${_customerTotalSpend.toStringAsFixed(0)} spent',
                      ),
                    ],
                  ),
                ],
              );
              return narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [avatar, const SizedBox(height: 16), details],
                    )
                  : Row(children: [
                      avatar,
                      const SizedBox(width: 18),
                      Expanded(child: details)
                    ]);
            },
          ),
        ),
        const SizedBox(height: 16),
        ...rows.map((row) => _buildCustomerProfileRow(row.$1, row.$2)),
        const SizedBox(height: 18),
        _buildCustomerFeatureGrid(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _startNewOrder,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New order'),
              style: FilledButton.styleFrom(
                backgroundColor: ColorPallets.deepBlue,
                foregroundColor: Colors.white,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _goToStep(5),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Orders'),
            ),
            OutlinedButton.icon(
              onPressed: _logoutCustomer,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerFeatureGrid() {
    final features = [
      (
        Icons.settings_rounded,
        'Settings',
        'Theme, sounds, performance, and app preferences',
        () {
          Navigator.of(context).pushNamed(SettingsScreen.routeName);
        },
      ),
      (
        Icons.favorite_rounded,
        'Favorite Stores',
        'Open saved frequent print stores',
        () {
          Navigator.of(context).pushNamed(FavoritesScreen.routeName);
        },
      ),
      (
        Icons.workspace_premium_rounded,
        'Rewards',
        'Referral rewards and Dittox Pro perks',
        () {
          Navigator.of(context).pushNamed(RewardsCenterScreen.routeName);
        },
      ),
      (
        Icons.support_agent_rounded,
        'Help & Support',
        'FAQ, issue reports, and feature voting',
        () {
          Navigator.of(context).pushNamed(SupportCenterScreen.routeName);
        },
      ),
      (
        Icons.storefront_rounded,
        'Become a Store',
        'Open the separate store website',
        () => unawaited(_goToStoreWebsite()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 760 ? 1 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 5.4 : 4.2,
          children: features
              .map((feature) => _buildCustomerFeatureCard(
                    icon: feature.$1,
                    title: feature.$2,
                    subtitle: feature.$3,
                    onTap: feature.$4,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCustomerFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ColorPallets.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: ColorPallets.deepBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ColorPallets.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ColorPallets.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: ColorPallets.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  color: ColorPallets.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  color: ColorPallets.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutPanel() {
    final shop = _selectedShop;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: ColorPallets.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Checkout summary',
                  style: TextStyle(
                    color: ColorPallets.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Rs ${_currentEstimate.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: ColorPallets.deepBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusPill(label: _fileName.isEmpty ? 'No file' : _fileName),
              _StatusPill(
                  label: shop?.storeName.isNotEmpty == true
                      ? shop!.storeName
                      : (shop?.name ?? 'No store')),
              _StatusPill(label: '$_copies copy${_copies == 1 ? '' : 'ies'}'),
              _StatusPill(label: _payLater ? 'PayLater' : 'Pay at pickup'),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final controls = [
                DropdownButtonFormField<String>(
                  initialValue: _fulfillmentMode,
                  decoration: const InputDecoration(labelText: 'Fulfillment'),
                  items: const ['Pickup', 'Delivery']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (value) => setState(
                      () => _fulfillmentMode = value ?? _fulfillmentMode),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _pickupSlot,
                  decoration: const InputDecoration(labelText: 'Time slot'),
                  items: const [
                    'Today, 6 PM - 8 PM',
                    'Tomorrow morning',
                    'Tomorrow evening',
                    'Store calls me'
                  ]
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _pickupSlot = value ?? _pickupSlot),
                ),
              ];
              return narrow
                  ? Column(
                      children: controls
                          .map((control) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: control,
                              ))
                          .toList(),
                    )
                  : Row(
                      children: controls
                          .map((control) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: control,
                                ),
                              ))
                          .toList(),
                    );
            },
          ),
          if (_fulfillmentMode == 'Delivery') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(labelText: 'Delivery address'),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Order options',
            style: TextStyle(
              color: ColorPallets.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 700;
              final toggles = [
                _buildCheckoutSwitch(
                  value: _rushOrder,
                  onChanged: (value) => setState(() => _rushOrder = value),
                  icon: Icons.flash_on_rounded,
                  title: 'Rush order',
                  subtitle: 'Adds Rs 20 to prioritize the job',
                ),
                _buildCheckoutSwitch(
                  value: _payLater,
                  onChanged: (value) => setState(() => _payLater = value),
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Use PayLater',
                  subtitle: 'Save as unpaid PayLater order',
                ),
              ];
              if (narrow) {
                return Column(
                  children: toggles
                      .map((toggle) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: toggle,
                          ))
                      .toList(),
                );
              }
              return Row(
                children: toggles
                    .map((toggle) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: toggle,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? ColorPallets.deepBlue : ColorPallets.cardBorder,
          width: value ? 1.4 : 1,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        secondary: Icon(icon, color: ColorPallets.deepBlue),
        activeThumbColor: ColorPallets.deepBlue,
        title: Text(
          title,
          style: const TextStyle(
            color: ColorPallets.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: ColorPallets.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  ThemeData _customerWebTheme(BuildContext context) {
    final base = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: ColorPallets.cardBorder),
    );
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      canvasColor: Colors.white,
      cardColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorPallets.deepBlue,
        brightness: Brightness.light,
        primary: ColorPallets.deepBlue,
        secondary: ColorPallets.lightBlue,
        surface: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: const TextStyle(
          color: ColorPallets.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(color: ColorPallets.textSecondary),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide:
              const BorderSide(color: ColorPallets.deepBlue, width: 1.4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ColorPallets.deepBlue),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorPallets.deepBlue,
          side: const BorderSide(color: ColorPallets.deepBlue),
        ),
      ),
    );
  }

  Widget _buildCustomerHeaderTabs() {
    const tabs = [
      (Icons.home_rounded, 'Home', -1),
      (Icons.receipt_long_rounded, 'Orders', 5),
      (Icons.person_rounded, 'Profile', 6),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ColorPallets.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final selected = _customerTab == tab.$3 ||
              (tab.$3 == -1 && _customerTab >= 0 && _customerTab <= 4);
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => _goToStep(tab.$3),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? ColorPallets.deepBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.$1,
                      size: 18,
                      color: selected ? Colors.white : ColorPallets.deepBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.$2,
                      style: TextStyle(
                        color: selected ? Colors.white : ColorPallets.deepBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _customerEmail.isNotEmpty;
    final userLabel = _customerName.isNotEmpty
        ? _customerName
        : (_customerEmail.isNotEmpty ? _customerEmail : 'Guest');
    final width = MediaQuery.sizeOf(context).width;
    return Theme(
      data: _customerWebTheme(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        body: SelectionArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  color: Colors.white,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_iphone_rounded,
                              color: ColorPallets.deepBlue),
                          const SizedBox(width: 12),
                          const Text(
                            'Dittox Customer App',
                            style: TextStyle(
                              color: ColorPallets.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          const Spacer(),
                          if (signedIn) _buildCustomerHeaderTabs(),
                          if (signedIn) const SizedBox(width: 14),
                          TextButton(
                            onPressed: _goHome,
                            child: const Text('Website'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: signedIn
                                ? () => setState(() => _customerTab = 6)
                                : _showCustomerLogin,
                            icon: Icon(signedIn
                                ? Icons.person_rounded
                                : Icons.login_rounded),
                            label: Text(signedIn ? userLabel : 'Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                signedIn
                    ? _buildWebAppDashboard(width, userLabel)
                    : _buildLoginGate(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WebStoreScreen extends StatefulWidget {
  const WebStoreScreen({super.key});

  @override
  State<WebStoreScreen> createState() => _WebStoreScreenState();
}

class _WebStoreScreenState extends State<WebStoreScreen> {
  Map<String, dynamic>? _activeStore;
  bool _loadingStore = true;
  final _storeEmailController = TextEditingController();
  final _storePasswordController = TextEditingController();
  int _storeTab = 0;
  bool _storeLoginLoading = false;
  bool _ordersLoading = false;
  bool _actionBusy = false;
  bool _autoAccept = false;
  bool _autoPrint = false;
  bool _autoSettingsLoading = false;
  bool _autoSettingsSaving = false;
  int _autoPrintCopies = 1;
  String _autoPrintQuality = '80gsm';
  Timer? _storeRefreshTimer;
  StreamSubscription<void>? _storeOrderChangesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _storeCloudOrderChangesSub;
  List<Map<String, dynamic>> _storeOrders = <Map<String, dynamic>>[];
  bool _storeOrdersRefreshing = false;
  bool _storeOrdersRefreshQueued = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
    _storeOrderChangesSub = DemoOrdersStore.changes.listen((_) {
      _refreshStoreOrdersSoon();
    });
    _storeRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _activeStore == null) return;
      unawaited(_loadStoreOrders(showLoading: false));
    });
  }

  @override
  void dispose() {
    _storeEmailController.dispose();
    _storePasswordController.dispose();
    _storeRefreshTimer?.cancel();
    _storeOrderChangesSub?.cancel();
    _storeCloudOrderChangesSub?.cancel();
    super.dispose();
  }

  void _refreshStoreOrdersSoon() {
    if (!mounted || _activeStore == null) return;
    unawaited(_loadStoreOrders(showLoading: false));
  }

  void _startStoreOrderWatch() {
    _storeCloudOrderChangesSub?.cancel();
    final storeId = _activeStoreId;
    if (storeId.trim().isEmpty) return;
    _storeCloudOrderChangesSub = DemoOrdersStore.watchStoreOrders(
      storeId: storeId,
    ).listen(
      (_) => _refreshStoreOrdersSoon(),
      onError: (_) {},
    );
  }

  Future<void> _loadStore() async {
    final store = await StoreAuthStore.getActiveStore();
    if (!mounted) return;
    setState(() {
      _activeStore = store;
      if (store == null) {
        _storeCloudOrderChangesSub?.cancel();
        _storeCloudOrderChangesSub = null;
        _autoAccept = false;
        _autoPrint = false;
        _autoPrintCopies = 1;
        _autoPrintQuality = '80gsm';
      }
      _loadingStore = false;
    });
    _startStoreOrderWatch();
    await _loadAutoSettings();
    await _loadStoreOrders();
  }

  String get _activeStoreId {
    final store = _activeStore;
    if (store == null) return '';
    return (store['linkedStoreId'] ?? store['id'] ?? '').toString();
  }

  Future<void> _loadStoreOrders({bool showLoading = true}) async {
    if (_activeStore == null) return;
    if (_storeOrdersRefreshing) {
      _storeOrdersRefreshQueued = true;
      return;
    }
    _storeOrdersRefreshing = true;
    var shouldShowLoading = showLoading;
    try {
      do {
        _storeOrdersRefreshQueued = false;
        if (mounted && shouldShowLoading) {
          setState(() => _ordersLoading = true);
        }
        var orders = await DemoOrdersStore.getStoreOrders(
          storeId: _activeStoreId,
          storeName: (_activeStore?['storeName'] ?? '').toString(),
          storeEmail: (_activeStore?['email'] ?? '').toString(),
          storeContactNumber: (_activeStore?['phoneNumber'] ?? '').toString(),
        );
        orders = await _applyStoreAutoModeRules(orders);
        orders.removeWhere((order) {
          final status = _normalizedStatus(order['status']);
          return status == 'collected' ||
              status == 'rejected' ||
              status == 'failed';
        });
        orders.sort((a, b) {
          final aDate = DateTime.tryParse((a['orderDate'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse((b['orderDate'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        if (!mounted) return;
        setState(() {
          _storeOrders = orders;
          if (shouldShowLoading) _ordersLoading = false;
        });
        shouldShowLoading = false;
      } while (_storeOrdersRefreshQueued && mounted);
    } finally {
      _storeOrdersRefreshing = false;
      if (mounted && showLoading && _ordersLoading) {
        setState(() => _ordersLoading = false);
      }
    }
  }

  Future<void> _loadAutoSettings() async {
    final storeId = _activeStoreId;
    if (_activeStore == null || storeId.trim().isEmpty) return;
    if (mounted) setState(() => _autoSettingsLoading = true);
    final settings = await ShopAutoModeStore.getAllSettings(storeId);
    if (!mounted) return;
    setState(() {
      _autoAccept = settings['autoAccept'] == true;
      _autoPrint = settings['autoPrint'] == true;
      _autoPrintCopies = (settings['printCopies'] as int?) ?? 1;
      _autoPrintQuality = (settings['printQuality'] as String?) ?? '80gsm';
      _autoSettingsLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _applyStoreAutoModeRules(
    List<Map<String, dynamic>> orders,
  ) async {
    if (!_autoAccept && !_autoPrint) return orders;

    var accepted = 0;
    var printing = 0;
    final output = <Map<String, dynamic>>[];
    for (final item in orders) {
      final order = Map<String, dynamic>.from(item);
      var status = _normalizedStatus(order['status']);
      if (status == 'collected' || status == 'rejected' || status == 'failed') {
        output.add(order);
        continue;
      }

      final orderId = (order['orderId'] ?? '').toString();
      if (_autoAccept && status == 'pending') {
        order['status'] = 'accepted';
        status = 'accepted';
        accepted++;
        if (orderId.isNotEmpty) {
          await DemoOrdersStore.updateOrderStatus(
            orderId: orderId,
            status: 'accepted',
          );
        }
      }

      if (_autoPrint && status == 'accepted') {
        order['status'] = 'printing';
        printing++;
        if (orderId.isNotEmpty) {
          await DemoOrdersStore.updateOrderStatus(
            orderId: orderId,
            status: 'printing',
          );
        }
      }

      output.add(order);
    }

    if ((accepted > 0 || printing > 0) && mounted) {
      if (accepted > 0 && printing > 0) {
        _notifyInfo(
          'Auto Mode ran',
          '$accepted accepted and $printing moved into printing.',
        );
      } else if (accepted > 0) {
        _notifyInfo(
            'Auto Mode accepted orders', '$accepted order(s) accepted.');
      } else {
        _notifyInfo(
          'Auto Mode started printing',
          '$printing order(s) moved into printing.',
        );
      }
    }
    return output;
  }

  Future<void> _saveAutoSettings({bool reloadOrders = true}) async {
    final storeId = _activeStoreId;
    if (storeId.trim().isEmpty || _autoSettingsSaving) return;
    setState(() => _autoSettingsSaving = true);
    try {
      await ShopAutoModeStore.setAutoAcceptEnabled(storeId, _autoAccept);
      await ShopAutoModeStore.setAutoPrintEnabled(storeId, _autoPrint);
      await ShopAutoModeStore.setPrintCopies(storeId, _autoPrintCopies);
      await ShopAutoModeStore.setPrintQuality(storeId, _autoPrintQuality);
      if (reloadOrders) await _loadStoreOrders();
    } finally {
      if (mounted) setState(() => _autoSettingsSaving = false);
    }
  }

  Future<void> _toggleAutoAccept(bool value) async {
    setState(() => _autoAccept = value);
    await _saveAutoSettings();
    if (!mounted) return;
    _notifySuccess(
      value ? 'Auto Accept enabled' : 'Auto Accept disabled',
      value
          ? 'Pending orders will move to accepted on refresh.'
          : 'New orders will wait for manual review.',
    );
  }

  Future<void> _toggleAutoPrint(bool value) async {
    setState(() => _autoPrint = value);
    await _saveAutoSettings();
    if (!mounted) return;
    _notifySuccess(
      value ? 'Auto Print enabled' : 'Auto Print disabled',
      value
          ? 'Accepted orders will move to printing on refresh.'
          : 'Accepted orders will stay in the print queue.',
    );
  }

  Future<void> _openBrowserPrintForOrder(Map<String, dynamic> order) async {
    final orderId = (order['orderId'] ?? '').toString();
    final bodyHtml = await _storeOrderPrintHtml(order);
    if (!mounted) return;
    final opened = triggerBrowserPrintHtml(
      title: orderId.isEmpty ? 'Dittox print order' : 'Dittox $orderId',
      bodyHtml: bodyHtml,
    );
    if (!opened) {
      _notifyError(
          'Print unavailable', 'Browser print is only available on web.');
      return;
    }

    final status = _normalizedStatus(order['status']);
    if (orderId.isNotEmpty && status != 'printing' && status != 'ready') {
      setState(() => _actionBusy = true);
      try {
        await DemoOrdersStore.updateOrderStatus(
          orderId: orderId,
          status: 'printing',
        );
        await _loadStoreOrders();
      } finally {
        if (mounted) setState(() => _actionBusy = false);
      }
    }
    if (!mounted) return;
    _notifySuccess(
      'Print popup opened',
      orderId.isEmpty
          ? 'Choose your printer in the browser dialog.'
          : '$orderId is ready in the browser print dialog.',
    );
  }

  Future<String> _storeOrderPrintHtml(Map<String, dynamic> order) async {
    final orderId = _htmlText((order['orderId'] ?? 'Website order').toString());
    final status = _htmlText(_normalizedStatus(order['status']));
    final store = _htmlText((order['storeName'] ?? 'Dittox Store').toString());
    final total = _storeDisplayOrderTotal(order).toStringAsFixed(0);
    final pages = _htmlText((order['totalPages'] ?? '0').toString());
    final fulfillment =
        _htmlText((order['fulfillmentMode'] ?? 'Pickup').toString());
    final slot = _htmlText((order['pickupSlot'] ?? '').toString());
    final payment = _htmlText((order['paymentStatus'] ?? '').toString());
    final placedAt = _htmlText((order['orderDate'] ?? '').toString());
    final customerName =
        _htmlText((order['customerName'] ?? 'Customer app user').toString());
    final customerEmail = _htmlText((order['customerEmail'] ?? '').toString());
    final deliveryAddress =
        _htmlText((order['deliveryAddress'] ?? '').toString());
    final items = (order['items'] as List?) ?? const <dynamic>[];
    final itemRows = items.isEmpty
        ? '<tr><td colspan="9">No document item details saved.</td></tr>'
        : items.map((item) {
            final map = item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{};
            final itemCost = _storeItemEstimatedTotal(map).toStringAsFixed(0);
            final notes = _itemNotesForPrint(map);
            return '<tr>'
                '<td>${_htmlText(_fileNameFromOrderItem(map))}</td>'
                '<td>${_htmlText((map['totalPages'] ?? '-').toString())}</td>'
                '<td>${_htmlText((map['copies'] ?? 1).toString())}</td>'
                '<td>${_htmlText((map['paperSize'] ?? '-').toString())}</td>'
                '<td>${_htmlText((map['side'] ?? '-').toString())}</td>'
                '<td>${_htmlText((map['itemColor'] ?? '-').toString())}</td>'
                '<td>${_htmlText((map['binding'] ?? 'No binding').toString())}</td>'
                '<td>${notes.isEmpty ? '-' : notes}</td>'
                '<td>Rs $itemCost</td>'
                '</tr>';
          }).join();
    final documentPages = await _customerDocumentPrintPages(items);

    return '''
<section class="print-page job-ticket">
  <div class="header">
    <div>
      <h1>Dittox Print Job</h1>
      <div class="muted">Invoice and job ticket for store printing</div>
    </div>
    <div style="text-align:right">
      <div class="total">Rs $total</div>
      <div class="muted">$status</div>
    </div>
  </div>

  <div>
    <span class="pill">$orderId</span>
    <span class="pill">$pages pages</span>
    <span class="pill">$fulfillment</span>
    ${slot.isEmpty ? '' : '<span class="pill">$slot</span>'}
    ${payment.isEmpty ? '' : '<span class="pill">$payment</span>'}
  </div>

  <div class="invoice-grid">
    <div>
      <h2>Customer</h2>
      <table>
        <tr><th>Name</th><td>$customerName</td></tr>
        <tr><th>Email</th><td>${customerEmail.isEmpty ? 'Not saved' : customerEmail}</td></tr>
        <tr><th>Delivery</th><td>${deliveryAddress.isEmpty ? fulfillment : deliveryAddress}</td></tr>
      </table>
    </div>
    <div>
      <h2>Store</h2>
      <table>
        <tr><th>Store</th><td>$store</td></tr>
        <tr><th>Address</th><td>${_htmlText((order['storeAddress'] ?? '').toString())}</td></tr>
        <tr><th>Contact</th><td>${_htmlText((order['storeContactNumber'] ?? '').toString())}</td></tr>
      </table>
    </div>
  </div>

  <h2>Documents</h2>
  <table>
    <thead>
      <tr>
        <th>File</th>
        <th>Pages</th>
        <th>Copies</th>
        <th>Paper</th>
        <th>Sides</th>
        <th>Color</th>
        <th>Binding</th>
        <th>Notes</th>
        <th>Cost</th>
      </tr>
    </thead>
    <tbody>$itemRows</tbody>
  </table>

  <div class="signature-row">
    <div><strong>Placed</strong><br><span class="muted">${placedAt.isEmpty ? 'Website order' : placedAt}</span></div>
    <div><strong>Store check</strong><br><span class="muted">File printed as specified</span></div>
    <div><strong>Customer pickup</strong><br><span class="muted">Signature / confirmation</span></div>
  </div>

  <div class="footer muted">
    Page 1 is the Dittox invoice/job ticket. Customer file pages follow separately when printable file data was saved with the order.
  </div>
</section>
$documentPages
''';
  }

  Future<String> _customerDocumentPrintPages(List<dynamic> items) async {
    if (items.isEmpty) {
      return _customerDocumentFallbackPage(
        title: 'Customer File',
        message: 'No customer document item was saved with this order.',
      );
    }

    final pages = <String>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final map =
          item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      final fileName = _htmlText(_fileNameFromOrderItem(map));
      final source = await _resolvedDocumentSourceFromOrderItem(map);
      final mimeType = _documentMimeType(map, source);
      if (source.isNotEmpty &&
          (source.startsWith('data:image/') || mimeType.startsWith('image/'))) {
        pages.add('''
<section class="print-page customer-file-page">
  <div class="doc-header"><strong>Customer File ${i + 1}</strong><span>$fileName</span></div>
  <div class="doc-stage"><img class="doc-image" src="${_htmlText(source)}" alt="$fileName"></div>
</section>
''');
      } else if (source.isNotEmpty &&
          (source.startsWith('data:application/pdf') ||
              mimeType == 'application/pdf')) {
        pages.add('''
<section class="print-page customer-file-page">
  <div class="doc-header"><strong>Customer File ${i + 1}</strong><span>$fileName</span></div>
  <object class="doc-frame" data="${_htmlText(source)}" type="application/pdf">
    <iframe class="doc-frame" src="${_htmlText(source)}" title="$fileName"></iframe>
  </object>
</section>
''');
      } else {
        pages.add(_customerDocumentFallbackPage(
          title: 'Customer File ${i + 1}',
          message:
              'Printable file data is not embedded for $fileName. This can happen for older orders that only saved the file name.',
        ));
      }
    }
    return pages.join();
  }

  Future<String> _resolvedDocumentSourceFromOrderItem(
    Map<String, dynamic> item,
  ) async {
    final source = _documentSourceFromOrderItem(item);
    if (!source.startsWith('firestore_chunks:')) return source;
    final parts = source.split(':');
    if (parts.length < 3) return '';
    final orderId = parts[1].trim();
    final expectedChunks = int.tryParse(parts[2].trim()) ?? 0;
    if (orderId.isEmpty || expectedChunks < 1) return '';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders_demo')
          .doc(orderId)
          .collection('file_chunks')
          .orderBy('index')
          .get()
          .timeout(const Duration(seconds: 8));
      if (snapshot.docs.length < expectedChunks) return '';
      return snapshot.docs
          .map((doc) => (doc.data()['data'] ?? '').toString())
          .join();
    } catch (_) {
      return '';
    }
  }

  String _customerDocumentFallbackPage({
    required String title,
    required String message,
  }) {
    return '''
<section class="print-page customer-file-page">
  <div class="doc-header"><strong>${_htmlText(title)}</strong><span>Dittox customer document</span></div>
  <div class="doc-fallback">
    <h2>${_htmlText(title)}</h2>
    <p>${_htmlText(message)}</p>
  </div>
</section>
''';
  }

  String _documentSourceFromOrderItem(Map<String, dynamic> item) {
    return (item['downloadUrl'] ??
            item['documentUrl'] ??
            item['documents'] ??
            '')
        .toString()
        .trim();
  }

  String _documentMimeType(Map<String, dynamic> item, String source) {
    final explicit = (item['mimeType'] ?? item['contentType'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (explicit.isNotEmpty) return explicit;

    final notes = (item['notes'] ?? '').toString().split(RegExp(r'\r?\n'));
    for (final line in notes) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('mimetype=')) {
        return trimmed.substring('mimeType='.length).trim().toLowerCase();
      }
    }

    if (source.startsWith('data:')) {
      final end = source.indexOf(';');
      if (end > 5) return source.substring(5, end).toLowerCase();
    }

    final name = _fileNameFromOrderItem(item).toLowerCase();
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    return '';
  }

  String _itemNotesForPrint(Map<String, dynamic> item) {
    final lines = (item['notes'] ?? '')
        .toString()
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) =>
            line.isNotEmpty && !line.toLowerCase().startsWith('mimetype='))
        .map(_htmlText)
        .toList();
    return lines.join('<br>');
  }

  String _fileNameFromOrderItem(Map<String, dynamic> item) {
    final explicit = (item['fileName'] ?? item['name'] ?? '').toString().trim();
    if (explicit.isNotEmpty) return explicit;
    final raw = _documentSourceFromOrderItem(item);
    if (raw.startsWith('data:')) return 'Uploaded document';
    if (raw.isEmpty) return 'Document';
    return raw;
  }

  double _storeDisplayOrderTotal(Map<String, dynamic> order) {
    final saved = double.tryParse((order['totalCost'] ?? 0).toString()) ?? 0;
    if (saved > 0) return saved;
    final items = (order['items'] as List?) ?? const <dynamic>[];
    return items.fold<double>(0, (total, item) {
      final map =
          item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      return total + _storeItemEstimatedTotal(map);
    });
  }

  double _storeItemEstimatedTotal(Map<String, dynamic> item) {
    final saved = double.tryParse((item['itemCost'] ?? 0).toString()) ?? 0;
    if (saved > 0) return saved;
    final pages = int.tryParse((item['totalPages'] ?? 1).toString()) ?? 1;
    final copies = int.tryParse((item['copies'] ?? 1).toString()) ?? 1;
    final color = (item['itemColor'] ?? '').toString().toLowerCase();
    final rate = color.contains('color') ? 10.0 : 2.0;
    return pages * copies * rate;
  }

  String _htmlText(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  Future<void> _submitStoreLogin() async {
    final email = _storeEmailController.text.trim();
    final password = _storePasswordController.text.trim();
    if (email.isEmpty || password.isEmpty || _storeLoginLoading) return;
    setState(() => _storeLoginLoading = true);
    final error = await StoreAuthStore.loginStore(
      email: email,
      password: password,
    );
    if (!mounted) return;
    setState(() => _storeLoginLoading = false);
    if (error != null) {
      _notifyError('Store login failed', error);
      return;
    }
    await _loadStore();
    _notifySuccess('Store mode opened', 'Your store queue is ready.');
  }

  String _normalizedStatus(dynamic value) {
    final raw = (value ?? 'pending').toString().trim().toLowerCase();
    if (raw == 'in_printing' || raw == 'inprinting' || raw == 'in-progress') {
      return 'printing';
    }
    if (raw == 'completed') return 'collected';
    if (raw.isEmpty) return 'pending';
    return raw;
  }

  List<Map<String, dynamic>> _ordersForStatuses(Set<String> statuses) {
    return _storeOrders
        .where((order) => statuses.contains(_normalizedStatus(order['status'])))
        .toList();
  }

  int _countStatus(String status) {
    return _storeOrders
        .where((order) => _normalizedStatus(order['status']) == status)
        .length;
  }

  Future<void> _changeStoreOrderStatus(
    Map<String, dynamic> order,
    String nextStatus,
  ) async {
    final orderId = (order['orderId'] ?? '').toString();
    if (orderId.isEmpty || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final normalized = _normalizedStatus(nextStatus);
      final ok = normalized == 'collected'
          ? await DemoOrdersStore.deleteOrder(orderId: orderId)
          : await DemoOrdersStore.updateOrderStatus(
              orderId: orderId,
              status: normalized,
            );
      if (!mounted) return;
      if (!ok) {
        _notifyError('Order update failed', 'Could not update this order.');
        return;
      }
      await _loadStoreOrders();
      _notifySuccess(
        normalized == 'collected' ? 'Order collected' : 'Order moved',
        normalized == 'collected'
            ? '$orderId was removed from active queue.'
            : '$orderId is now $normalized.',
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Color _storeStatusColor(String status) {
    return switch (_normalizedStatus(status)) {
      'pending' => Colors.orange,
      'accepted' => ColorPallets.lightBlue,
      'printing' => const Color(0xFF5D5FEF),
      'ready' => Colors.green,
      'collected' => Colors.grey,
      'rejected' => Colors.red,
      _ => ColorPallets.deepBlue,
    };
  }

  void _notifyError(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addError(title: title, body: body);
  }

  void _notifySuccess(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addSuccess(title: title, body: body);
  }

  void _notifyInfo(String title, String body) {
    context.read<AppNotifications>().dismissAll();
    context.read<AppNotifications>().addInfo(title: title, body: body);
  }

  Future<void> _goHome() async {
    await launchUrl(Uri.base.resolve('/'), webOnlyWindowName: '_self');
  }

  Future<void> _showStoreLogin() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit() async {
            final email = emailController.text.trim();
            final password = passwordController.text.trim();
            if (email.isEmpty || password.isEmpty || loading) return;
            setDialogState(() => loading = true);
            final error = await StoreAuthStore.loginStore(
              email: email,
              password: password,
            );
            if (!dialogContext.mounted) return;
            if (error != null) {
              setDialogState(() => loading = false);
              _notifyError('Store login failed', error);
              return;
            }
            Navigator.of(dialogContext).pop();
            await _loadStore();
            _notifySuccess(
                'Store portal opened', 'Welcome back to Dittox Store.');
          }

          return AlertDialog(
            title: const Text('Store Portal Login'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This is the separate store website. Login with your Store Mode account.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Store email'),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    loading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: loading ? null : submit,
                child: Text(loading ? 'Opening...' : 'Open portal'),
              ),
            ],
          );
        },
      ),
    );

    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _logoutStore() async {
    await StoreAuthStore.logoutStore();
    await _loadStore();
    if (!mounted) return;
    setState(() {
      _storeOrders = <Map<String, dynamic>>[];
      _storeTab = 0;
    });
    _notifySuccess('Signed out', 'Store portal session closed.');
  }

  Widget _buildStoreLoginGate() {
    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 84),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 36,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final copy = Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1B22), Color(0xFF102A56)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(34),
                  bottomLeft: Radius.circular(34),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DarkBadge(label: 'Store mode website'),
                  SizedBox(height: 22),
                  Text(
                    'Login to run your print store from the website.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      height: 0.98,
                      letterSpacing: -1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Accept orders, move them to printing, mark ready for pickup, collect, and review store profile details from a desktop-friendly screen.',
                    style: TextStyle(
                      color: Color(0xFFD7E5EA),
                      fontSize: 16,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
            final form = Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Store login',
                    style: TextStyle(
                      color: ColorPallets.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Use the Store Mode account created inside Dittox.',
                    style: TextStyle(
                      color: ColorPallets.textSecondary,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _storeEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Store email'),
                    onSubmitted: (_) => _submitStoreLogin(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _storePasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => _submitStoreLogin(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _storeLoginLoading ? null : _submitStoreLogin,
                    icon: const Icon(Icons.storefront_rounded),
                    label: Text(_storeLoginLoading
                        ? 'Opening store mode...'
                        : 'Open store mode'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorPallets.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                  ),
                ],
              ),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: copy),
                      Expanded(child: form),
                    ],
                  )
                : Column(children: [copy, form]);
          },
        ),
      ),
    );
  }

  Widget _buildStoreModeApp(double width, String storeName) {
    final wide = width >= 980;
    return _PageSection(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$storeName store mode',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              height: 1,
              letterSpacing: -1.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Full web queue for accepting, printing, ready pickup, and collected orders.',
            style: TextStyle(
              color: Color(0xFFB9C9CF),
              fontSize: 17,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 292, child: _buildStoreSidebar(storeName)),
                      Expanded(child: _buildStoreContent()),
                    ],
                  )
                : Column(
                    children: [
                      _buildStoreSidebar(storeName),
                      _buildStoreContent(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSidebar(String storeName) {
    const tabs = [
      (Icons.dashboard_rounded, 'Overview'),
      (Icons.inbox_rounded, 'New orders'),
      (Icons.print_rounded, 'Printing'),
      (Icons.task_alt_rounded, 'Ready'),
      (Icons.auto_awesome_rounded, 'Auto Mode'),
      (Icons.store_mall_directory_rounded, 'Profile'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1B22),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(34),
          bottomLeft: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DarkBadge(label: 'Full store mode'),
          const SizedBox(height: 18),
          Text(
            storeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_storeOrders.length} live order${_storeOrders.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final selected = _storeTab == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _storeTab = index),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(tab.$1, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        tab.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _logoutStore,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: switch (_storeTab) {
        0 => _buildStoreOverview(),
        1 => _buildStoreQueueScreen(
            eyebrow: 'Step 1',
            title: 'Accept new orders.',
            body:
                'Review pending customer jobs and accept them into your store queue.',
            statuses: const {'pending'},
          ),
        2 => _buildStoreQueueScreen(
            eyebrow: 'Step 2',
            title: 'Print active jobs.',
            body:
                'Pending, accepted, and printing jobs appear here so uploaded files are visible from the print menu.',
            statuses: const {'pending', 'accepted', 'printing'},
          ),
        3 => _buildStoreQueueScreen(
            eyebrow: 'Step 3',
            title: 'Ready for pickup.',
            body:
                'Orders marked ready stay here until collected by the customer.',
            statuses: const {'ready'},
          ),
        4 => _buildStoreAutoModeScreen(),
        _ => _buildStoreProfileScreen(),
      },
    );
  }

  Widget _buildStoreOverview() {
    final pending = _countStatus('pending');
    final accepted = _countStatus('accepted');
    final printing = _countStatus('printing');
    final ready = _countStatus('ready');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                eyebrow: 'Store dashboard',
                title: 'Today\'s print queue.',
                body:
                    'This is the real website store mode. Use the queue screens to move each order through accepted, printing, ready, and collected.',
              ),
            ),
            IconButton(
              onPressed: _loadStoreOrders,
              tooltip: 'Refresh queue',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            final cards = [
              _StoreMetricCard('New', pending.toString(), Colors.orange),
              _StoreMetricCard(
                  'Accepted', accepted.toString(), ColorPallets.lightBlue),
              _StoreMetricCard(
                  'Printing', printing.toString(), const Color(0xFF5D5FEF)),
              _StoreMetricCard('Ready', ready.toString(), Colors.green),
            ];
            return narrow
                ? Column(
                    children: cards
                        .map((card) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: card,
                            ))
                        .toList(),
                  )
                : Row(
                    children: cards
                        .map((card) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: card,
                              ),
                            ))
                        .toList(),
                  );
          },
        ),
        const SizedBox(height: 22),
        _buildStoreAutoModeBanner(),
        const SizedBox(height: 18),
        _buildStoreQueueList(
          _storeOrders.take(5).toList(),
          emptyText: 'No store orders yet. Customer web orders appear here.',
        ),
      ],
    );
  }

  Widget _buildStoreQueueScreen({
    required String eyebrow,
    required String title,
    required String body,
    required Set<String> statuses,
  }) {
    final orders = _ordersForStatuses(statuses);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionTitle(
                eyebrow: eyebrow,
                title: title,
                body: body,
              ),
            ),
            IconButton(
              onPressed: _loadStoreOrders,
              tooltip: 'Refresh queue',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_ordersLoading)
          const Center(child: CircularProgressIndicator())
        else
          _buildStoreQueueList(
            orders,
            emptyText: 'No ${statuses.join('/')} orders right now.',
          ),
      ],
    );
  }

  Widget _buildStoreQueueList(
    List<Map<String, dynamic>> orders, {
    required String emptyText,
  }) {
    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          emptyText,
          style: const TextStyle(
            color: ColorPallets.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Column(
      children: orders
          .map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStoreOrderCard(order),
              ))
          .toList(),
    );
  }

  Widget _buildStoreOrderCard(Map<String, dynamic> order) {
    final orderId = (order['orderId'] ?? 'Website order').toString();
    final status = _normalizedStatus(order['status']);
    final total = _storeDisplayOrderTotal(order);
    final pages = (order['totalPages'] ?? 0).toString();
    final fileNames = _fileNamesFromOrder(order);
    final primaryFileName = fileNames.isEmpty ? 'Document' : fileNames.first;
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _storeStatusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: _storeStatusColor(status)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryFileName,
                      style: const TextStyle(
                        color: ColorPallets.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$orderId - $pages pages - Rs ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: ColorPallets.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: status),
            ],
          ),
          const SizedBox(height: 14),
          _buildStoreFileList(fileNames),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusPill(
                  label: (order['fulfillmentMode'] ?? 'Pickup').toString()),
              _StatusPill(
                  label: (order['pickupSlot'] ?? 'Store slot').toString()),
              _StatusPill(
                  label: (order['paymentStatus'] ?? 'payment').toString()),
            ],
          ),
          const SizedBox(height: 14),
          _buildStoreOrderActions(order, status),
        ],
      ),
    );
  }

  List<String> _fileNamesFromOrder(Map<String, dynamic> order) {
    final names = <String>[];
    final items = (order['items'] as List?) ?? const <dynamic>[];
    for (final item in items) {
      final map =
          item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      final name = _fileNameFromOrderItem(map).trim();
      if (name.isNotEmpty && name != 'Document' && !names.contains(name)) {
        names.add(name);
      }
    }

    final rawNames = order['fileNames'];
    if (rawNames is List) {
      for (final raw in rawNames) {
        final name = raw.toString().trim();
        if (name.isNotEmpty && !names.contains(name)) names.add(name);
      }
    }

    final primary = (order['primaryFileName'] ?? '').toString().trim();
    if (primary.isNotEmpty && !names.contains(primary)) {
      names.insert(0, primary);
    }
    return names;
  }

  Widget _buildStoreFileList(List<String> fileNames) {
    final names = fileNames.isEmpty ? const ['Document'] : fileNames;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorPallets.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Files to print',
            style: TextStyle(
              color: ColorPallets.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...names.map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded,
                      size: 18, color: ColorPallets.deepBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: ColorPallets.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreOrderActions(Map<String, dynamic> order, String status) {
    final actions = <Widget>[];
    if (status == 'pending') {
      actions.add(_storeActionButton(
          order, 'Accept order', 'accepted', Icons.check_rounded));
    }
    if (status == 'accepted') {
      actions.add(_storePrintButton(order));
      actions.add(_storeActionButton(
          order, 'Start printing', 'printing', Icons.print_rounded));
    }
    if (status == 'printing') {
      actions.add(_storePrintButton(order));
      actions.add(_storeActionButton(
          order, 'Mark ready', 'ready', Icons.task_alt_rounded));
    }
    if (status == 'ready') {
      actions.add(_storeActionButton(
          order, 'Collected', 'collected', Icons.done_all_rounded));
    }
    actions.add(
      TextButton.icon(
        onPressed: _actionBusy ? null : () => _showStoreOrderDetails(order),
        icon: const Icon(Icons.open_in_full_rounded),
        label: const Text('Details'),
      ),
    );
    return Wrap(spacing: 10, runSpacing: 10, children: actions);
  }

  Widget _storePrintButton(Map<String, dynamic> order) {
    return FilledButton.icon(
      onPressed: _actionBusy ? null : () => _openBrowserPrintForOrder(order),
      icon: const Icon(Icons.print_rounded),
      label: const Text('Print now'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0D7C66),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _storeActionButton(
    Map<String, dynamic> order,
    String label,
    String nextStatus,
    IconData icon,
  ) {
    return FilledButton.icon(
      onPressed:
          _actionBusy ? null : () => _changeStoreOrderStatus(order, nextStatus),
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: ColorPallets.deepBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _showStoreOrderDetails(Map<String, dynamic> order) async {
    final items = (order['items'] as List?) ?? const <dynamic>[];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text((order['orderId'] ?? 'Order details').toString()),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _storeDetailLine('Status', _normalizedStatus(order['status'])),
                _storeDetailLine('Total',
                    'Rs ${_storeDisplayOrderTotal(order).toStringAsFixed(0)}'),
                _storeDetailLine('Fulfillment',
                    (order['fulfillmentMode'] ?? 'Pickup').toString()),
                _storeDetailLine(
                    'Slot', (order['pickupSlot'] ?? '').toString()),
                _storeDetailLine(
                    'Payment', (order['paymentStatus'] ?? '').toString()),
                const SizedBox(height: 12),
                const Text('Items',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text('No item details saved.')
                else
                  ...items.map((item) {
                    final map = item is Map
                        ? Map<String, dynamic>.from(item)
                        : <String, dynamic>{};
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${_fileNameFromOrderItem(map)} - ${map['totalPages'] ?? '-'} pages - ${map['copies'] ?? 1} copies',
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _storeDetailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: ColorPallets.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreAutoModeBanner() {
    final enabled = _autoAccept || _autoPrint;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFEFFAF5) : const Color(0xFFF3F7F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: enabled
              ? Colors.green.withValues(alpha: 0.28)
              : ColorPallets.cardBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final copy = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (enabled ? Colors.green : ColorPallets.deepBlue)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color:
                      enabled ? Colors.green.shade700 : ColorPallets.deepBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled ? 'Auto Mode is on' : 'Auto Mode is off',
                      style: const TextStyle(
                        color: ColorPallets.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _autoPrint
                          ? 'Orders can move automatically into printing. Browser print popup still needs the Print now click.'
                          : 'Turn on Auto Accept or Auto Print to move orders through the queue faster.',
                      style: const TextStyle(
                        color: ColorPallets.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = FilledButton.icon(
            onPressed: () => setState(() => _storeTab = 4),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Open Auto Mode'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorPallets.deepBlue,
              foregroundColor: Colors.white,
            ),
          );
          return narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [copy, const SizedBox(height: 12), action],
                )
              : Row(children: [Expanded(child: copy), action]);
        },
      ),
    );
  }

  Widget _buildStoreAutoModeScreen() {
    if (_autoSettingsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                eyebrow: 'Auto Mode',
                title: 'Hands-off store flow.',
                body:
                    'Auto Accept moves pending orders to accepted. Auto Print moves accepted orders to printing. The browser print dialog is opened from the Print now button because browsers block unattended print popups.',
              ),
            ),
            IconButton(
              onPressed: _autoSettingsSaving ? null : _loadStoreOrders,
              tooltip: 'Apply Auto Mode to queue',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1B22), Color(0xFF102A56)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 34),
              const SizedBox(height: 14),
              Text(
                _autoAccept && _autoPrint
                    ? 'Fast lane active'
                    : _autoAccept
                        ? 'Auto accept active'
                        : _autoPrint
                            ? 'Auto print queue active'
                            : 'Manual queue active',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _autoPrint
                    ? 'Accepted jobs enter printing automatically. Click Print now on an order to open the browser print popup.'
                    : 'Use Auto Print when staff wants accepted orders queued for printing without extra status taps.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _autoAccept,
          onChanged: _autoSettingsSaving ? null : _toggleAutoAccept,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: const Text('Auto Accept orders'),
          subtitle: const Text(
              'Pending customer orders become accepted on queue refresh.'),
          secondary: const Icon(Icons.check_circle_rounded),
        ),
        SwitchListTile(
          value: _autoPrint,
          onChanged: _autoSettingsSaving ? null : _toggleAutoPrint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: const Text('Auto Print queue'),
          subtitle:
              const Text('Accepted orders move into printing automatically.'),
          secondary: const Icon(Icons.local_printshop_rounded),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;
            final controls = [
              DropdownButtonFormField<int>(
                initialValue: _autoPrintCopies,
                decoration: const InputDecoration(labelText: 'Default copies'),
                items: const [1, 2, 3, 4, 5]
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value'),
                        ))
                    .toList(),
                onChanged: _autoSettingsSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _autoPrintCopies = value);
                        unawaited(_saveAutoSettings(reloadOrders: false));
                      },
              ),
              DropdownButtonFormField<String>(
                initialValue: _autoPrintQuality,
                decoration: const InputDecoration(labelText: 'Paper quality'),
                items: const ['80gsm', '100gsm', 'bond']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                              value == 'bond' ? 'Bond' : value.toUpperCase()),
                        ))
                    .toList(),
                onChanged: _autoSettingsSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _autoPrintQuality = value);
                        unawaited(_saveAutoSettings(reloadOrders: false));
                      },
              ),
            ];
            return narrow
                ? Column(
                    children: controls
                        .map((control) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: control,
                            ))
                        .toList(),
                  )
                : Row(
                    children: controls
                        .map((control) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: control,
                              ),
                            ))
                        .toList(),
                  );
          },
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _autoSettingsSaving ? null : _loadStoreOrders,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
              _autoSettingsSaving ? 'Saving...' : 'Apply to current queue'),
          style: FilledButton.styleFrom(
            backgroundColor: ColorPallets.deepBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreProfileScreen() {
    final store = _activeStore ?? const <String, dynamic>{};
    final rows = [
      ('Store name', (store['storeName'] ?? 'Dittox Store').toString()),
      ('Owner', (store['ownerName'] ?? '').toString()),
      ('Email', (store['email'] ?? '').toString()),
      ('Phone', (store['phoneNumber'] ?? '').toString()),
      ('Address', (store['storeAddress'] ?? '').toString()),
      (
        'Hours',
        '${store['openingTime'] ?? ''} - ${store['closingTime'] ?? ''}'
      ),
      ('Linked store ID', _activeStoreId),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          eyebrow: 'Store profile',
          title: 'Your store mode account.',
          body:
              'These details come from the Store Mode account and are used to match customer website orders to your queue.',
        ),
        const SizedBox(height: 18),
        ...rows.map((row) => _buildStoreProfileRow(row.$1, row.$2)),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _logoutStore,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout store mode'),
          style: FilledButton.styleFrom(
            backgroundColor: ColorPallets.deepBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  color: ColorPallets.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  color: ColorPallets.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeName = (_activeStore?['storeName'] ?? 'Dittox Store').toString();
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: const Color(0xFF0E232C),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                color: const Color(0xFF0A1B22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Dittox Store Website',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _goHome,
                          child: const Text('Customer site'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _activeStore == null
                              ? _showStoreLogin
                              : () => setState(() => _storeTab = 5),
                          icon: const Icon(Icons.login_rounded),
                          label: Text(
                              _activeStore == null ? 'Store login' : storeName),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: ColorPallets.deepBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_loadingStore)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (_activeStore == null)
                _buildStoreLoginGate()
              else
                _buildStoreModeApp(width, storeName),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StoreMetricCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: ColorPallets.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: const Center(
        child: Text(
          'Dittox web UI - Firebase Hosting on Spark/free plan',
          style: TextStyle(
            color: ColorPallets.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
