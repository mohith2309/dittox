import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import 'package:provider/provider.dart';

import '../../helpers/user_location.dart';
import '../../providers/current_user.dart';
import '../../utils/color_pallets.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/formatters.dart';
import '../../utils/location_history_store.dart';
import '../../widgets/home/inviteCont.dart';
import '../../widgets/home/scanDoc.dart';
import '../../widgets/home/topBar.dart';
import '../../widgets/home/uploadDoc.dart';
import '../Orders/historyOrders.dart';
import '../additional/favorites_screen.dart';
import '../additional/rewards_center_screen.dart';
import '../additional/support_center_screen.dart';
import 'cart_Screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = "/homeScreen";
  final String accessToken;

  const HomeScreen({super.key, required this.accessToken});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  bool _didInitUser = false;
  int _todayOrders = 0;
  int _activeOrders = 0;
  double _todayRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadOrderStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitUser) return;
    _didInitUser = true;

    final curUser = Provider.of<CurrentUser>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.accessToken.trim().isNotEmpty) {
        curUser.loadUserByAccessToken(widget.accessToken).then((_) {
          _autoDetectLocation(curUser);
        });
      } else {
        _autoDetectLocation(curUser);
      }
    });
  }

  Future<void> _autoDetectLocation(CurrentUser curUser) async {
    final hasLocation = curUser.latitude != 0 && curUser.longitude != 0;
    final hasPlaceName =
        curUser.placeName.isNotEmpty && curUser.placeName != "Bangalore";

    if (!hasLocation || !hasPlaceName) {
      try {
        final position = await UserLocation.getUserLatLong();
        final placeMark = await UserLocation.getUserPlaceMarks(
          position.latitude,
          position.longitude,
        );

        curUser.updateUserLocation(position.latitude, position.longitude);
        curUser.updateUserPlaceName(placeMark["locality"] ?? "");
        curUser.updateUserCountry(placeMark["country"] ?? "");

        await LocationHistoryStore.addLocation(
          placeName: placeMark["locality"] ?? "Current Location",
          latitude: position.latitude,
          longitude: position.longitude,
          country: placeMark["country"],
        );
      } catch (_) {}
    }
  }

  Future<void> _loadOrderStats() async {
    final orders = await DemoOrdersStore.getOrders();
    final now = DateTime.now();
    var todayOrders = 0;
    var activeOrders = 0;
    var todayRevenue = 0.0;

    for (final order in orders) {
      final createdAt =
          DateTime.tryParse((order["orderDate"] ?? "").toString())?.toLocal();
      final isToday = createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
      final status = (order["status"] ?? "").toString().toLowerCase();
      final amount = double.tryParse((order["totalCost"] ?? 0).toString()) ?? 0;

      if (isToday) {
        todayOrders++;
        todayRevenue += amount;
      }
      if (status != "collected" &&
          status != "completed" &&
          status != "rejected" &&
          status != "failed") {
        activeOrders++;
      }
    }

    if (!mounted) return;
    setState(() {
      _todayOrders = todayOrders;
      _activeOrders = activeOrders;
      _todayRevenue = todayRevenue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cityName = context.select((CurrentUser u) => u.getPlaceName);
    final width = MediaQuery.sizeOf(context).width;
    final isWideWeb = kIsWeb && width >= 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CartScreen(
                accessToken: widget.accessToken,
              ),
            ),
          );
        },
        backgroundColor: ColorPallets.deepBlue,
        icon: const Icon(Icons.receipt_long),
        label: const Text("Orders"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideWeb ? 1180 : double.infinity,
                      ),
                      child: TopCont(
                        cityName: cityName,
                        ctx: context,
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        setState(() => isLoading = true);
                        await _loadOrderStats();
                        if (mounted) setState(() => isLoading = false);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          isWideWeb ? 24 : 16,
                          12,
                          isWideWeb ? 24 : 16,
                          100,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isWideWeb ? 1180 : double.infinity,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatsCard(),
                                const SizedBox(height: 14),
                                const InviteCont(),
                                const SizedBox(height: 18),
                                _buildQuickActionsSection(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorPallets.deepBlue,
            ColorPallets.lightBlue.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorPallets.deepBlue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                "Today's Activity",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatTile("Orders", _todayOrders.toString()),
              const SizedBox(width: 10),
              _buildStatTile(
                  "Revenue", CurrencyFormatter.formatCompact(_todayRevenue)),
              const SizedBox(width: 10),
              _buildStatTile("Active", _activeOrders.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
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
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final isWideWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              color: ColorPallets.deepBlue,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              "Quick Actions",
              style: TextStyle(
                color: ColorPallets.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          "Upload or scan and place your print order instantly.",
          style: TextStyle(
            color: ColorPallets.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        if (isWideWeb)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 174,
                  child: UploadDoc(
                    ctx: context,
                    accessToken: widget.accessToken,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 174,
                  child: ScanDoc(
                    ctx: context,
                  ),
                ),
              ),
            ],
          )
        else ...[
          SizedBox(
            height: 154,
            child: UploadDoc(
              ctx: context,
              accessToken: widget.accessToken,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 154,
            child: ScanDoc(
              ctx: context,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (isWideWeb)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 5.4,
            children: [
              _buildQuickReorderCard(context),
              _buildFavoritesCard(context),
              _buildRewardsCard(context),
              _buildSupportCard(context),
            ],
          )
        else ...[
          _buildQuickReorderCard(context),
          const SizedBox(height: 12),
          _buildFavoritesCard(context),
          const SizedBox(height: 12),
          _buildRewardsCard(context),
          const SizedBox(height: 12),
          _buildSupportCard(context),
        ],
      ],
    );
  }

  Widget _buildRewardsCard(BuildContext context) {
    return _buildHomeShortcutCard(
      context: context,
      routeName: RewardsCenterScreen.routeName,
      icon: Icons.workspace_premium_rounded,
      title: "Rewards & Referrals",
      subtitle: "Check in, spin, copy referral codes",
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return _buildHomeShortcutCard(
      context: context,
      routeName: SupportCenterScreen.routeName,
      icon: Icons.support_agent_rounded,
      title: "Help & Support",
      subtitle: "FAQ, issue reports, feature voting",
    );
  }

  Widget _buildHomeShortcutCard({
    required BuildContext context,
    required String routeName,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(routeName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ColorPallets.deepBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorPallets.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ColorPallets.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: ColorPallets.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(FavoritesScreen.routeName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: ColorPallets.deepBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Favorite Stores",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorPallets.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Open your saved frequent stores",
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorPallets.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: ColorPallets.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReorderCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoryOrders(accessToken: widget.accessToken),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.replay_rounded,
                  color: ColorPallets.deepBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Reorder",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorPallets.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Reorder from your previous orders",
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorPallets.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: ColorPallets.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
