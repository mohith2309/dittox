import "dart:io";

// import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:url_launcher/url_launcher.dart";
// import 'package:app_settings/app_settings.dart';
// import 'package:open_settings/open_settings.dart';

import "../../providers/current_user.dart";
import "../../utils/color_pallets.dart";
import "../../utils/dynamicSizing.dart";
import "../../utils/pill_notifications.dart";
import "../../utils/store_auth_store.dart";
import "../../utils/user_stats_store.dart";
import "../../utils/user_preferences_store.dart";
import "../../utils/wallet_store.dart";
import "../Orders/historyOrders.dart";
import "../Orders/paylaterOrders.dart";
import "../additional/aboutUs.dart";
import "../additional/contactUs.dart";
import "../additional/rewards_center_screen.dart";
import "../additional/settings_screen.dart";
import "../additional/support_center_screen.dart";
import "../auth/auth_screen.dart";
import "../payments/play_billing_screen.dart";
import "../store/store_login_screen.dart";
import "../store/store_mode_screen.dart";

class ProfilePage extends StatefulWidget {
  static const routeName = "/profileScreen";
  final String accessToken;
  const ProfilePage({super.key, required this.accessToken});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  SharedPreferences? prefs;
  bool isLoading = false;
  double walletBalance = 0;
  bool isProSubscriber = false;
  double discountSaved = 0;
  double topupBonusSaved = 0;
  String proPlan = "";
  String profilePhotoPath = "";

  @override
  void initState() {
    initSharePref();
    _loadWallet();
    _loadProStats();
    _loadProfilePhoto();
    super.initState();
  }

  Future<void> _loadProfilePhoto() async {
    final path = await UserPreferencesStore.getProfilePhotoPath();
    if (!mounted) return;
    setState(() => profilePhotoPath = path);
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    await UserPreferencesStore.setProfilePhotoPath(path);
    await _loadProfilePhoto();
  }

  void initSharePref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadWallet() async {
    final balance = await WalletStore.getBalance(widget.accessToken);
    if (!mounted) return;
    setState(() {
      walletBalance = balance;
    });
  }

  Future<void> _loadProStats() async {
    final pro = await UserStatsStore.isProSubscriber();
    final saved = await UserStatsStore.getDiscountSaved();
    final bonusSaved = await UserStatsStore.getTopupBonusSaved();
    final plan = await UserStatsStore.getProPlan();
    if (!mounted) return;
    setState(() {
      isProSubscriber = pro;
      discountSaved = saved;
      topupBonusSaved = bonusSaved;
      proPlan = plan;
    });
  }

  void _showProPerksSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dittox Pro Perks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text("Plan: ${proPlan.isEmpty ? "pro_monthly" : proPlan}"),
              const SizedBox(height: 6),
              Text(
                  "Order discount saved: ₹${discountSaved.toStringAsFixed(2)}"),
              const SizedBox(height: 6),
              Text(
                  "Top-up bonus saved: ₹${topupBonusSaved.toStringAsFixed(2)}"),
              const SizedBox(height: 10),
              const Text("• 10% discount on checkout"),
              const Text("• 10% wallet top-up bonus"),
              const Text("• Priority support on print issues"),
            ],
          ),
        ),
      ),
    );
  }

  void logout(BuildContext ctx) async {
    debugPrint("logout button is pressed");
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final localPrefs = prefs ?? await SharedPreferences.getInstance();
      prefs = localPrefs;
      await FirebaseAuth.instance.signOut();
      await localPrefs.remove("AccessToken");
      await localPrefs.remove("UseDemoMode");
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (ctx) => const AuthScreen(),
          ),
          (route) => false);
    } catch (e) {
      debugPrint("error during logout: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final curUser = Provider.of<CurrentUser>(context);
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    final hasProfilePhoto = !kIsWeb &&
        profilePhotoPath.isNotEmpty &&
        File(profilePhotoPath).existsSync();

    return Scaffold(
      appBar: AppBar(
        foregroundColor: ColorPallets.white,
        title: const Text(
          "User Profile",
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            tooltip: "Rewards",
            onPressed: () =>
                Navigator.of(context).pushNamed(RewardsCenterScreen.routeName),
            icon: const Icon(Icons.workspace_premium_rounded),
          ),
          IconButton(
            tooltip: "Support",
            onPressed: () =>
                Navigator.of(context).pushNamed(SupportCenterScreen.routeName),
            icon: const Icon(Icons.support_agent_rounded),
          ),
          IconButton(
            tooltip: "Settings",
            onPressed: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            // height: 20,
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 50,
              // heightSpecific: true,
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              // top: 10,
              // bottom: 20,
              // left: 5,
              // right: 10,
              top: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: true,
              ),
              bottom: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 40,
                // heightSpecific: true,
              ),
              left: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 10,
                // heightSpecific: false,
              ),
              right: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: false,
              ),
            ),
            margin: EdgeInsets.only(
              // left: 10,
              // right: 10,
              // bottom: 20,
              bottom: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: true,
              ),
              left: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: false,
              ),
              right: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: false,
              ),
            ),
            decoration: BoxDecoration(
                color: ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  // 14,
                  calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 14,
                    // heightSpecific: true,
                  ),
                )),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          curUser.getUserName,
                          style: TextStyle(
                            color: ColorPallets.deepBlue,
                            // fontSize: 35,
                            fontSize: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 60,
                              // heightSpecific: true,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          // height: 10,
                          height: calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 15,
                            // heightSpecific: true,
                          ),
                        ),
                        Text(
                          curUser.getUserEmail,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isProSubscriber)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Dittox Pro Active",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    )),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _pickProfilePhoto,
                    borderRadius: BorderRadius.circular(80),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: ColorPallets.lightPurplishWhile
                              .withValues(alpha: 0.35),
                          backgroundImage: hasProfilePhoto
                              ? FileImage(File(profilePhotoPath))
                              : null,
                          child: !hasProfilePhoto
                              ? Text(
                                  curUser.getUserName.isEmpty
                                      ? "U"
                                      : curUser.getUserName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: ColorPallets.deepBlue,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: ColorPallets.deepBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // SizedBox(
                //   // width: 10,
                //   width: calculateDynamicFontSize(
                //     totalScreenHeight: totalScreenHeight,
                //     totalScreenWidth: totalScreenWidth,
                //     currentFontSize: 30,
                //     // heightSpecific: false,
                //   ),
                // )
              ],
            ),
          ),
          SizedBox(
            // height: 20,
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: true,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                // width: 20,
                width: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 30,
                  // heightSpecific: false,
                ),
              ),
              Text(
                "Your Information",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: ColorPallets.black,
                    // fontSize: 24,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 45,
                      // heightSpecific: true,
                    ),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(
            // height: 10,
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 30,
              // heightSpecific: true,
            ),
          ),
          Expanded(
              child: ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              Container(
                margin: EdgeInsets.symmetric(
                  // horizontal: 10,
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                    // heightSpecific: false,
                  ),
                ),
                // padding:
                //     const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: false,
                    )),
                decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      // 14,
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 20,
                        // heightSpecific: true,
                      ),
                    )),
                child: ListTile(
                  title: Text(
                    "Wallet Balance",
                    style: TextStyle(
                      color: ColorPallets.deepBlue,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    "₹${walletBalance.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 30,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: _loadWallet,
                    icon:
                        const Icon(Icons.refresh, color: ColorPallets.deepBlue),
                  ),
                ),
              ),
              SizedBox(
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                    )),
                decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 20,
                      ),
                    )),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlayBillingScreen(),
                      ),
                    );
                    if (!isProSubscriber) {
                      PillNotifications.show(
                        context,
                        message: "Subscribe to Dittox Pro to unlock discounts.",
                        type: PillType.info,
                      );
                    }
                  },
                  title: Text(
                    "Dittox Pro",
                    style: TextStyle(
                      color: ColorPallets.deepBlue,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    isProSubscriber
                        ? "Active: ${proPlan.isEmpty ? "pro_monthly" : proPlan} • Saved ₹${(discountSaved + topupBonusSaved).toStringAsFixed(2)}"
                        : "Subscribe via Razorpay",
                    style: TextStyle(
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 25,
                      ),
                    ),
                  ),
                  trailing: const FaIcon(
                    FontAwesomeIcons.arrowRight,
                    color: ColorPallets.deepBlue,
                  ),
                ),
              ),
              if (isProSubscriber) ...[
                SizedBox(
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 20,
                      ),
                    ),
                  ),
                  child: ListTile(
                    onTap: _showProPerksSheet,
                    title: Text(
                      "Pro Perks",
                      style: TextStyle(
                        color: ColorPallets.deepBlue,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                        ),
                      ),
                    ),
                    subtitle: Text(
                      "View your Pro savings and premium benefits",
                      style: TextStyle(
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 25,
                        ),
                      ),
                    ),
                    trailing: FaIcon(
                      FontAwesomeIcons.crown,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
              SizedBox(
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                    )),
                decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 20,
                      ),
                    )),
                child: ListTile(
                  onTap: () async {
                    if (kIsWeb) {
                      await launchUrl(
                        Uri.base.resolve('/store'),
                        webOnlyWindowName: '_self',
                      );
                      return;
                    }
                    final isLoggedIn = await StoreAuthStore.isStoreLoggedIn();
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => isLoggedIn
                            ? const StoreModeScreen()
                            : const StoreLoginScreen(),
                      ),
                    );
                  },
                  title: Text(
                    "Become a Store",
                    style: TextStyle(
                      color: ColorPallets.deepBlue,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    "Manage orders: accept, print, ready, collected",
                    style: TextStyle(
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 25,
                      ),
                    ),
                  ),
                  trailing: const FaIcon(
                    FontAwesomeIcons.shop,
                    color: ColorPallets.deepBlue,
                  ),
                ),
              ),
              SizedBox(
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  // horizontal: 10,
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                    // heightSpecific: false,
                  ),
                ),
                // padding:
                //     const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: false,
                    )),
                decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      // 14,
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 20,
                        // heightSpecific: true,
                      ),
                    )),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PayLater(accessToken: widget.accessToken),
                      ),
                    );
                  },
                  title: Text(
                    "PayLater Orders",
                    style: TextStyle(
                      color: ColorPallets.deepBlue,
                      // fontSize: 18,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                        // heightSpecific: true,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    "Make payment for Saved Orders",
                    style: TextStyle(
                      // fontSize: 12,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 25,
                        // heightSpecific: true,
                      ),
                    ),
                  ),
                  trailing: const FaIcon(
                    FontAwesomeIcons.arrowRight,
                    color: ColorPallets.deepBlue,
                  ),
                ),
              ),
              SizedBox(
                // height: 10,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  // horizontal: 10,
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                    // heightSpecific: false,
                  ),
                ),
                // padding:
                //     const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: false,
                    )),
                decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      // 14,
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 20,
                        // heightSpecific: true,
                      ),
                    )),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            HistoryOrders(accessToken: widget.accessToken),
                      ),
                    );
                  },
                  title: Text(
                    "History Orders",
                    style: TextStyle(
                      color: ColorPallets.deepBlue,
                      // fontSize: 18,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                        // heightSpecific: true,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    "Find the completed Orders",
                    style: TextStyle(
                      // fontSize: 12,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 25,
                        // heightSpecific: true,
                      ),
                    ),
                  ),
                  trailing: const FaIcon(
                    FontAwesomeIcons.arrowRight,
                    color: ColorPallets.deepBlue,
                  ),
                ),
              ),
              SizedBox(
                // height: 10,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
              ),
              // Container(
              //   margin: EdgeInsets.symmetric(
              //     // horizontal: 10,
              //     horizontal: calculateDynamicFontSize(
              //       totalScreenHeight: totalScreenHeight,
              //       totalScreenWidth: totalScreenWidth,
              //       currentFontSize: 20,
              //       // heightSpecific: false,
              //     ),
              //   ),
              //   // padding:
              //   //     const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              //   padding: EdgeInsets.symmetric(
              //       vertical: calculateDynamicFontSize(
              //         totalScreenHeight: totalScreenHeight,
              //         totalScreenWidth: totalScreenWidth,
              //         currentFontSize: 20,
              //         // heightSpecific: true,
              //       ),
              //       horizontal: calculateDynamicFontSize(
              //         totalScreenHeight: totalScreenHeight,
              //         totalScreenWidth: totalScreenWidth,
              //         currentFontSize: 20,
              //         // heightSpecific: false,
              //       )),
              //   decoration: BoxDecoration(
              //       color: ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
              //       borderRadius: BorderRadius.circular(
              //         // 14,
              //         calculateDynamicFontSize(
              //           totalScreenHeight: totalScreenHeight,
              //           totalScreenWidth: totalScreenWidth,
              //           currentFontSize: 20,
              //           // heightSpecific: true,
              //         ),
              //       )),
              //   child: ListTile(
              //     onTap: () {
              //       // AppSettings.openBluetoothSettings();
              //       // OpenSettings.openNotificationSetting();
              //     },
              //     title: Text(
              //       "Notifications",
              //       style: TextStyle(
              //         color: ColorPallets.deepBlue,
              //         // fontSize: 18,
              //         fontSize: calculateDynamicFontSize(
              //           totalScreenHeight: totalScreenHeight,
              //           totalScreenWidth: totalScreenWidth,
              //           currentFontSize: 40,
              //           // heightSpecific: true,
              //         ),
              //       ),
              //     ),
              //     subtitle: Text(
              //       "Change the notification setting",
              //       style: TextStyle(
              //         // fontSize: 12,
              //         fontSize: calculateDynamicFontSize(
              //           totalScreenHeight: totalScreenHeight,
              //           totalScreenWidth: totalScreenWidth,
              //           currentFontSize: 30,
              //           // heightSpecific: true,
              //         ),
              //       ),
              //     ),
              //     trailing: const Icon(
              //       FontAwesomeIcons.arrowRight,
              //       color: ColorPallets.deepBlue,
              //     ),
              //   ),
              // ),
              SizedBox(
                // height: 10,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 10,
                  // heightSpecific: true,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  // horizontal: 10,
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                    // heightSpecific: false,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: false,
                    )),
                decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      // 14,
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 20,
                        // heightSpecific: true,
                      ),
                    )),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed(ContactUs.routeName);
                  },
                  title: Text(
                    "Contact Us",
                    style: TextStyle(
                      color: ColorPallets.deepBlue,
                      // fontSize: 18,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                        // heightSpecific: true,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    "Share your experience , Complaints , Queries about Xerox app",
                    maxLines: 3,
                    style: TextStyle(
                      // fontSize: 12,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 25,
                        // heightSpecific: true,
                      ),
                    ),
                  ),
                  trailing: const FaIcon(
                    FontAwesomeIcons.arrowRight,
                    color: ColorPallets.deepBlue,
                  ),
                ),
              ),
              SizedBox(
                // height: 10,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  // horizontal: 10,
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                    // heightSpecific: false,
                  ),
                ),
                // padding:
                //     const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: false,
                    )),
                decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                        // 14,
                        calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ))),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed(AboutUs.routeName);
                  },
                  title: Text(
                    "About Us",
                    style: TextStyle(
                        color: ColorPallets.deepBlue,
                        // fontSize: 18,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                          // heightSpecific: true,
                        )),
                  ),
                  subtitle: Text(
                    "Know about Xerox App ",
                    maxLines: 3,
                    style: TextStyle(
                        // fontSize: 12,
                        fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 25,
                      // heightSpecific: true,
                    )),
                  ),
                  trailing: const FaIcon(
                    FontAwesomeIcons.arrowRight,
                    color: ColorPallets.deepBlue,
                  ),
                ),
              ),
              SizedBox(
                // height: 10,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                    // horizontal: 10,
                    horizontal: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                )),
                // padding:
                //     const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                padding: EdgeInsets.symmetric(
                    vertical: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ),
                    horizontal: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: false,
                    )),
                decoration: BoxDecoration(
                    color:
                        ColorPallets.lightPurplishWhile.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                        // 14,
                        calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ))),
                child: ListTile(
                  onTap: () {
                    logout(context);
                  },
                  title: Text(
                    "Logout",
                    style: TextStyle(
                        color: ColorPallets.deepBlue,
                        // fontSize: 18,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                          // heightSpecific: true,
                        )),
                  ),
                  subtitle: Text(
                    "Logout from device",
                    maxLines: 3,
                    style: TextStyle(
                        // fontSize: 12,
                        fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 25,
                      // heightSpecific: true,
                    )),
                  ),
                  trailing: isLoading
                      ? const CircularProgressIndicator(
                          color: ColorPallets.deepBlue,
                        )
                      : const FaIcon(
                          FontAwesomeIcons.arrowRightFromBracket,
                          color: ColorPallets.deepBlue,
                        ),
                ),
              ),
            ],
          ))
        ],
      ),
    );
  }
}
