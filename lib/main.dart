import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'providers/current_user.dart';
import 'providers/ListOfShops.dart';
import 'providers/search_place.dart';
import 'providers/seletedShop.dart';
import 'providers/ListOfPdfFiles.dart';
import 'providers/app_notifications.dart';
import 'providers/app_settings.dart';

import 'screens/additional/aboutUs.dart';
import 'screens/additional/contactUs.dart';
import 'screens/additional/notifications.dart';
import 'screens/additional/splashScreen.dart';
import 'screens/additional/summaryScreen.dart';
import 'screens/auth/forgetPasswordOTP.dart';
import 'screens/auth/forget_password_screen.dart';
import 'screens/auth/privacy_policy.dart';
import 'screens/auth/regsiterOtp.dart';
import 'screens/auth/termsandcondictions.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/maps/selectShops.dart';
import 'screens/maps/setLocationMaps.dart';
import 'screens/maps/textLocation.dart';
import 'screens/navBar_Screens/profile_Screen.dart';
import 'screens/nav_drawers/navBar.dart';
import 'screens/pdf/pdfFilter.dart';
import 'screens/pdf/scanImageToPdf.dart';
import 'screens/pdf/scannedPdfRender.dart';
import 'screens/Orders/historyOrders.dart';
import 'screens/Orders/order_confirmation_screen.dart';
import 'screens/Orders/paylaterOrders.dart';
import 'screens/Orders/order_tracking_screen.dart';
import 'screens/store/store_login_screen.dart';
import 'screens/store/store_mode_screen.dart';
import 'screens/store/print_queue_screen.dart';
import 'screens/web/web_home_screen.dart';
import 'screens/additional/auto_mode_screen.dart';
import 'screens/additional/favorites_screen.dart';
import 'screens/additional/rewards_center_screen.dart';
import 'screens/additional/settings_screen.dart';
import 'screens/additional/support_center_screen.dart';

import 'helpers/sqlLite.dart';
import 'utils/backend_feature_services.dart';
import 'utils/cloud_sync_guard.dart';
import 'utils/color_pallets.dart';
import 'widgets/home/samsung_notification.dart';
import 'firebase_options.dart';

final _cachedTextTheme = GoogleFonts.ubuntuTextTheme();
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!CloudSyncGuard.cloudSyncEnabled) {
    unawaited(() async {
      try {
        await FirebaseFirestore.instance.disableNetwork();
      } catch (_) {}
    }());
  }
  unawaited(BackendFeatureRegistry.publishRegistry());
  unawaited(SQLHelpers.initDatabase());
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final firebaseUser = FirebaseAuth.instance.currentUser;
  String? launchAccessToken = prefs.getString("AccessToken");
  const demoMode = false;
  if (firebaseUser != null) {
    try {
      launchAccessToken = await firebaseUser
          .getIdToken(false)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {}
    if (launchAccessToken != null) {
      await prefs.setString("AccessToken", launchAccessToken);
    }
  }

  runApp(Dittox(
    accessToken: launchAccessToken,
    demoMode: demoMode,
  ));
}

class Dittox extends StatelessWidget {
  final String? accessToken;
  final bool demoMode;

  const Dittox({
    super.key,
    required this.accessToken,
    required this.demoMode,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CurrentUser()),
        ChangeNotifierProvider(create: (context) => PlaceResult()),
        ChangeNotifierProvider(create: (context) => ListOfPDFFiles()),
        ChangeNotifierProvider(create: (context) => NearestShop()),
        ChangeNotifierProvider(create: (context) => seletedShop()),
        ChangeNotifierProvider(create: (context) => AppNotifications()),
        ChangeNotifierProvider(create: (context) => AppSettings()..load()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, appSettings, _) => MaterialApp(
          title: "Dittox",
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          themeMode: appSettings.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            textTheme: _cachedTextTheme,
            primaryColor: ColorPallets.deepBlue,
            scaffoldBackgroundColor: ColorPallets.surface,
            colorScheme: ColorScheme.fromSeed(
              seedColor: ColorPallets.deepBlue,
              primary: ColorPallets.deepBlue,
              secondary: ColorPallets.lightBlue,
              surface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: ColorPallets.deepBlue,
              foregroundColor: ColorPallets.white,
              elevation: 0,
              centerTitle: false,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: TextStyle(
                color: ColorPallets.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              iconTheme: IconThemeData(
                color: ColorPallets.white,
              ),
              actionsIconTheme: IconThemeData(
                color: ColorPallets.white,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(
                  color: ColorPallets.cardBorder,
                ),
              ),
            ),
            listTileTheme: const ListTileThemeData(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              iconColor: ColorPallets.deepBlue,
              textColor: ColorPallets.textPrimary,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: ColorPallets.cardBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: ColorPallets.cardBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: ColorPallets.deepBlue,
                  width: 1.6,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPallets.deepBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPallets.deepBlue,
                side: const BorderSide(color: ColorPallets.deepBlue),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: ColorPallets.textPrimary,
              contentTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titleTextStyle: const TextStyle(
                color: ColorPallets.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              contentTextStyle: const TextStyle(
                color: ColorPallets.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return ColorPallets.deepBlue;
                }
                return Colors.white;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return ColorPallets.lightBlue.withValues(alpha: 0.45);
                }
                return ColorPallets.cardBorder;
              }),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: ColorPallets.deepBlue,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: ColorPallets.deepBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              indicatorColor: ColorPallets.deepBlue.withValues(alpha: 0.12),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  fontSize: 12,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: states.contains(WidgetState.selected)
                      ? ColorPallets.deepBlue
                      : ColorPallets.textSecondary,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                return IconThemeData(
                  color: states.contains(WidgetState.selected)
                      ? ColorPallets.deepBlue
                      : ColorPallets.textSecondary,
                );
              }),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: ColorPallets.deepBlue,
              unselectedItemColor: ColorPallets.textSecondary,
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  TextStyle(fontWeight: FontWeight.w600),
              type: BottomNavigationBarType.fixed,
            ),
            dividerTheme: const DividerThemeData(
              color: ColorPallets.cardBorder,
              thickness: 1,
              space: 1,
            ),
            chipTheme: ChipThemeData(
              backgroundColor:
                  ColorPallets.lightPurplishWhile.withValues(alpha: 0.25),
              selectedColor: ColorPallets.lightBlue.withValues(alpha: 0.22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              labelStyle: const TextStyle(
                color: ColorPallets.deepBlue,
                fontWeight: FontWeight.w600,
              ),
              secondaryLabelStyle: const TextStyle(
                color: ColorPallets.deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            textTheme: _cachedTextTheme,
            primaryColor: ColorPallets.lightBlue,
            scaffoldBackgroundColor: const Color(0xFF0F1415),
            colorScheme: ColorScheme.fromSeed(
              seedColor: ColorPallets.lightBlue,
              brightness: Brightness.dark,
              primary: ColorPallets.lightBlue,
              secondary: ColorPallets.deepBlue,
              surface: const Color(0xFF161D1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0B3D3E),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              surfaceTintColor: Colors.transparent,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF161D1E),
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFF293436)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF101718),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            listTileTheme: const ListTileThemeData(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              iconColor: Color(0xFF4EC9CC),
              textColor: Color(0xFFE8F4F4),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF4EC9CC);
                }
                return Colors.grey.shade600;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF4EC9CC).withValues(alpha: 0.4);
                }
                return Colors.grey.shade800;
              }),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF4EC9CC),
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B5E5F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4EC9CC),
                side: const BorderSide(color: Color(0xFF4EC9CC)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: const Color(0xFF1E2A2B),
              selectedColor: const Color(0xFF0B5E5F),
              labelStyle: const TextStyle(
                color: Color(0xFF4EC9CC),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF161D1E),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1A2526),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFF2D3E40),
              thickness: 1,
              space: 1,
            ),
          ),
          builder: (context, child) {
            if (kIsWeb) {
              final path = Uri.base.path.toLowerCase();
              final content = path.startsWith('/app')
                  ? Theme(
                      data: _webCustomerLightTheme(Theme.of(context)),
                      child: child ?? const SizedBox.shrink(),
                    )
                  : child ?? const SizedBox.shrink();
              return Stack(
                children: [
                  content,
                  const SamsungNotificationStack(topRight: true),
                ],
              );
            }
            return _FcmNotificationBridge(
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: kIsWeb
              ? Uri.base.path.toLowerCase().startsWith('/store')
                  ? const WebStoreScreen()
                  : Uri.base.path.toLowerCase().startsWith('/app')
                      ? const WebCustomerAppScreen()
                      : WebHomeScreen(
                          accessToken: accessToken,
                          demoMode: demoMode,
                        )
              : DittoxSplash(accessToken: accessToken, demoMode: demoMode),
          routes: {
            if (kIsWeb) '/app': (context) => const WebCustomerAppScreen(),
            if (kIsWeb) '/store': (context) => const WebStoreScreen(),
            ForgetPasswordScreen.routeName: (context) =>
                const ForgetPasswordScreen(),
            TermsAndCond.routeName: (context) => const TermsAndCond(),
            PrivacyPolicy.routeName: (context) => const PrivacyPolicy(),
            ButtonNavigationBar.routeName: (context) =>
                ButtonNavigationBar(accessToken: accessToken ?? ""),
            PDFFilters.routeName: (context) => const PDFFilters(),
            SelectShops.routeName: (context) {
              final tok = Provider.of<CurrentUser>(context, listen: false)
                  .userAccessToken;
              final effective = (tok.trim().isNotEmpty &&
                      tok != 'Loading...' &&
                      tok != 'demo_token')
                  ? tok
                  : (accessToken ?? '');
              return SelectShops(accessToken: effective);
            },
            CheckoutScreen.routeName: (context) => const CheckoutScreen(),
            SummaryScreen.routeName: (context) {
              final tok = Provider.of<CurrentUser>(context, listen: false)
                  .userAccessToken;
              final effective = (tok.trim().isNotEmpty &&
                      tok != 'Loading...' &&
                      tok != 'demo_token')
                  ? tok
                  : (accessToken ?? '');
              return SummaryScreen(accessToken: effective);
            },
            ProfilePage.routeName: (context) {
              final tok = Provider.of<CurrentUser>(context, listen: false)
                  .userAccessToken;
              final effective = (tok.trim().isNotEmpty &&
                      tok != 'Loading...' &&
                      tok != 'demo_token')
                  ? tok
                  : (accessToken ?? '');
              return ProfilePage(accessToken: effective);
            },
            NotificationPage.routeName: (context) => const NotificationPage(),
            SetLocationMaps.routeName: (context) => const SetLocationMaps(),
            LocationText.routeName: (context) => const LocationText(),
            HistoryOrders.routeName: (context) {
              final tok = Provider.of<CurrentUser>(context, listen: false)
                  .userAccessToken;
              final effective = (tok.trim().isNotEmpty &&
                      tok != 'Loading...' &&
                      tok != 'demo_token')
                  ? tok
                  : (accessToken ?? '');
              return HistoryOrders(accessToken: effective);
            },
            PayLater.routeName: (context) {
              final tok = Provider.of<CurrentUser>(context, listen: false)
                  .userAccessToken;
              final effective = (tok.trim().isNotEmpty &&
                      tok != 'Loading...' &&
                      tok != 'demo_token')
                  ? tok
                  : (accessToken ?? '');
              return PayLater(accessToken: effective);
            },
            StoreLoginScreen.routeName: (context) => const StoreLoginScreen(),
            StoreModeScreen.routeName: (context) => const StoreModeScreen(),
            PrintQueueScreen.routeName: (context) => const PrintQueueScreen(),
            AboutUs.routeName: (context) => const AboutUs(),
            ContactUs.routeName: (context) => const ContactUs(),
            RegisterOtp.routeName: (context) => const RegisterOtp(),
            PasswordOTP.routeName: (context) => const PasswordOTP(),
            ScaneImageToPdf.routeName: (context) => const ScaneImageToPdf(),
            ScanPicrender.routeName: (context) =>
                ScanPicrender(accessToken: accessToken ?? ""),
            AutoModeScreen.routeName: (context) => const AutoModeScreen(),
            SettingsScreen.routeName: (context) => const SettingsScreen(),
            FavoritesScreen.routeName: (context) => const FavoritesScreen(),
            RewardsCenterScreen.routeName: (context) =>
                const RewardsCenterScreen(),
            SupportCenterScreen.routeName: (context) =>
                const SupportCenterScreen(),
            OrderConfirmationScreen.routeName: (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final order = args is Map<String, dynamic>
                  ? args
                  : const <String, dynamic>{};
              final tok = Provider.of<CurrentUser>(context, listen: false)
                  .userAccessToken;
              return OrderConfirmationScreen(order: order, accessToken: tok);
            },
            OrderTrackingScreen.routeName: (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final order = args is Map<String, dynamic>
                  ? args
                  : const <String, dynamic>{};
              return OrderTrackingScreen(order: order);
            },
          },
        ),
      ),
    );
  }
}

ThemeData _webCustomerLightTheme(ThemeData base) {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: const TextStyle(
        color: ColorPallets.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: ColorPallets.textSecondary),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: ColorPallets.deepBlue, width: 1.4),
      ),
    ),
  );
}

class _FcmNotificationBridge extends StatefulWidget {
  final Widget child;
  const _FcmNotificationBridge({required this.child});

  @override
  State<_FcmNotificationBridge> createState() => _FcmNotificationBridgeState();
}

class _FcmNotificationBridgeState extends State<_FcmNotificationBridge> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initMessaging();
  }

  Future<void> _initMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (token != null && token.trim().isNotEmpty && userId != null) {
        unawaited(
          NotificationOpsService.registerPushToken(
            userId: userId,
            token: token,
            platform: 'flutter',
          ),
        );
      }

      FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handleRemoteMessage(initial);
      }
    } catch (_) {}
  }

  void _handleRemoteMessage(RemoteMessage message) {
    if (!mounted) return;
    final notifs = context.read<AppNotifications>();
    final data = message.data;
    final title =
        message.notification?.title ?? data['title'] ?? 'Notification';
    final body = message.notification?.body ?? data['body'] ?? '';
    final type = (data['type'] ?? 'info').toString().toLowerCase();

    switch (type) {
      case 'success':
        notifs.addSuccess(title: title, body: body);
      case 'warning':
        notifs.addWarning(title: title, body: body);
      case 'error':
        notifs.addError(title: title, body: body);
      case 'offer':
        notifs.addOffer(title: title, body: body);
      case 'storealert':
      case 'store_alert':
        notifs.addStoreAlert(
          storeId: (data['storeId'] ?? '').toString(),
          title: title,
          body: body,
        );
      case 'orderupdate':
      case 'order_update':
        notifs.addOrderUpdate(
          orderId: (data['orderId'] ?? '').toString(),
          title: title,
          body: body,
          status: (data['status'] ?? 'pending').toString(),
        );
      default:
        notifs.addInfo(title: title, body: body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        SamsungNotificationStack(
          onTap: () {
            _navigatorKey.currentState?.pushNamed(NotificationPage.routeName);
          },
        ),
      ],
    );
  }
}
