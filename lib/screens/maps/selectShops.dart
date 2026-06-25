import 'dart:async';
import 'dart:math' as math;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/pdfFile.dart';
import '../../model/shop.dart';
import '../../providers/ListOfPdfFiles.dart';
import '../../providers/ListOfShops.dart';
import '../../providers/current_user.dart';
import '../../providers/seletedShop.dart';
import '../../utils/color_pallets_extended.dart';
import '../../utils/app_optimizations.dart';
import '../../utils/demo_data.dart';
import '../../utils/firestore_shop_service.dart';
import '../../utils/favorite_stores_store.dart';
import '../../utils/store_auth_store.dart';
import '../../widgets/common/pill_appbar_title.dart';
import '../checkout/checkout_screen.dart';

class SelectShops extends StatefulWidget {
  static const routeName = "/selectShops";
  final String accessToken;

  const SelectShops({super.key, required this.accessToken});

  @override
  State<SelectShops> createState() => _SelectShopsState();
}

class _SelectShopsState extends State<SelectShops> {
  late final Completer<GoogleMapController> _controller;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final TextEditingController _shopSearchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  bool _isLoading = false;
  String _shopQuery = "";
  String _sortBy = "distance";
  String _serviceFilter = "all";
  bool _openNowOnly = false;
  bool _rating4PlusOnly = false;
  double _maxPrice = 1000;
  final List<String> _recentSearches = <String>[];
  Set<String> _favoriteStoreIds = const <String>{};

  static const CameraPosition _bangalorePosition = CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _controller = Completer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllShops();
      _loadFavoriteIds();
    });
  }

  @override
  void dispose() {
    _shopSearchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteIds() async {
    final favs = await FavoriteStoresStore.load();
    if (!mounted) return;
    setState(() {
      _favoriteStoreIds = favs.map((f) => f.id).toSet();
    });
  }

  Future<void> _loadAllShops() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // 1. Try Firestore shop_profiles collection first
    List<Shop> remoteShops = await FirestoreShopService.loadShops();

    // 2. Fall back to bundled default shops if Firestore returns nothing
    if (remoteShops.isEmpty) {
      remoteShops = DemoData.getDefaultShops();
    }

    // 3. Always merge in locally-registered store mode shops
    final registeredShops =
        _registeredStoresToShops(await StoreAuthStore.getRegisteredStores());

    final shops = [...remoteShops, ...registeredShops];
    if (!mounted) return;
    final shopsList = Provider.of<NearestShop>(context, listen: false);
    final pdfList = Provider.of<ListOfPDFFiles>(context, listen: false);
    final currentUser = Provider.of<CurrentUser>(context, listen: false);

    // Clear previous
    try {
      shopsList.emptyList();
    } catch (_) {}

    for (int i = 0; i < shops.length; i++) {
      final shop = shops[i];
      shop.cost = _calculateTotalCost(pdfList.allPdfList, shop);
      final km = _distanceKm(
        currentUser.latitude,
        currentUser.longitude,
        shop.locationX,
        shop.locationY,
      );
      shop.distance = "${km.toStringAsFixed(1)} km";
      shopsList.addShop(shop);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (currentUser.latitude != 0 || currentUser.longitude != 0) {
      shopsList.allShops.sort((a, b) {
        final ad = _distanceKm(
          currentUser.latitude,
          currentUser.longitude,
          a.locationX,
          a.locationY,
        );
        final bd = _distanceKm(
          currentUser.latitude,
          currentUser.longitude,
          b.locationX,
          b.locationY,
        );
        return ad.compareTo(bd);
      });
    }
  }

  List<Shop> _registeredStoresToShops(List<Map<String, dynamic>> stores) {
    return stores.map((store) {
      final linkedStoreId =
          (store["linkedStoreId"] ?? store["id"] ?? "").toString();
      final storeName = (store["storeName"] ?? "Registered Store").toString();
      return Shop(
        id: linkedStoreId,
        name: storeName,
        storeName: storeName,
        address: (store["storeAddress"] ?? "").toString(),
        locationX: ((store["latitude"] as num?) ?? 12.9716).toDouble(),
        locationY: ((store["longitude"] as num?) ?? 77.5946).toDouble(),
        email: (store["email"] ?? "").toString(),
        contactNumber: (store["phoneNumber"] ?? "").toString(),
        openingTime: (store["openingTime"] ?? "").toString(),
        closingTime: (store["closingTime"] ?? "").toString(),
        avgRating: 4.5,
        distance: "Registered store",
        duration: "Pickup at selected time",
      );
    }).toList();
  }

  Future<void> _goToLocation(double lat, double lng, double zoom) async {
    if (!_controller.isCompleted) return;
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: zoom),
      ),
    );
  }

  double _calculateTotalCost(List<PdfData> pdfFiles, Shop shop) {
    double total = 0;
    for (final pdf in pdfFiles) {
      total += pdf.selectedPagesCount * 2.0 * pdf.copies;
    }
    return total;
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  double _distanceValue(String distance) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(distance);
    return double.tryParse(match?.group(1) ?? '') ?? double.infinity;
  }

  Set<Marker> _markersForVisibleShops(List<Shop> shops) {
    return shops.asMap().entries.map((entry) {
      final index = entry.key;
      final shop = entry.value;
      final markerId = shop.id.trim().isNotEmpty
          ? shop.id.trim()
          : '${shop.locationX},${shop.locationY},$index';
      return Marker(
        markerId: MarkerId(markerId),
        position: LatLng(shop.locationX, shop.locationY),
        infoWindow: InfoWindow(title: shop.name),
        onTap: () {
          _goToLocation(shop.locationX, shop.locationY, 16);
          _carouselController.animateToPage(index);
        },
      );
    }).toSet();
  }

  void _autoSelectBestShop(List<Shop> shops) {
    if (shops.isEmpty) return;
    final currentUser = Provider.of<CurrentUser>(context, listen: false);

    double bestScore = double.infinity;
    int bestIndex = 0;

    for (int i = 0; i < shops.length; i++) {
      final shop = shops[i];
      final distance = _distanceKm(
        currentUser.latitude,
        currentUser.longitude,
        shop.locationX,
        shop.locationY,
      );
      final ratingScore = 5.0 - shop.avgRating;
      final priceScore = shop.cost;

      double score =
          (distance * 0.5) + (ratingScore * 0.3) + (priceScore * 0.2);
      if (score < bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    _carouselController.animateToPage(bestIndex);
    final shop = shops[bestIndex];
    _goToLocation(shop.locationX, shop.locationY, 16);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Auto-selected: ${shop.storeName} (${shop.distance})"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopsList = Provider.of<NearestShop>(context);
    final seletedShopProvider = Provider.of<seletedShop>(context);
    final size = MediaQuery.sizeOf(context);

    final visibleShops = shopsList.allShops.where((shop) {
      final q = _shopQuery.trim().toLowerCase();
      final queryMatch = q.isEmpty ||
          shop.name.toLowerCase().contains(q) ||
          shop.storeName.toLowerCase().contains(q) ||
          shop.address.toLowerCase().contains(q) ||
          _serviceText(shop).toLowerCase().contains(q);
      final ratingMatch = !_rating4PlusOnly || shop.avgRating >= 4;
      final priceMatch = shop.cost <= _maxPrice;
      final openMatch = !_openNowOnly || _isShopOpenNow(shop);
      final serviceMatch = _serviceFilter == "all" ||
          _serviceText(shop).toLowerCase().contains(_serviceFilter);
      return queryMatch &&
          ratingMatch &&
          priceMatch &&
          openMatch &&
          serviceMatch;
    }).toList()
      ..sort((a, b) {
        // Favourites always come first
        final aFav = _favoriteStoreIds.contains(a.id) ? 0 : 1;
        final bFav = _favoriteStoreIds.contains(b.id) ? 0 : 1;
        if (aFav != bFav) return aFav.compareTo(bFav);
        if (_sortBy == "rating") return b.avgRating.compareTo(a.avgRating);
        if (_sortBy == "price") return a.cost.compareTo(b.cost);
        return _distanceValue(a.distance).compareTo(_distanceValue(b.distance));
      });
    final visibleMarkers = _markersForVisibleShops(visibleShops);
    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Select Shop',
          icon: Icons.store_mall_directory_rounded,
        ),
        backgroundColor: ColorPalletsExtended.deepBlue,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: "distance", child: Text("Nearest First")),
              const PopupMenuItem(
                  value: "rating", child: Text("Highest Rated")),
              const PopupMenuItem(value: "price", child: Text("Lowest Price")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: "Auto-Select Best Shop",
            onPressed: () => _autoSelectBestShop(visibleShops),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _bangalorePosition,
            markers: visibleMarkers,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) _controller.complete(controller);
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _shopSearchController,
                    onChanged: (value) {
                      // Optimization: Debounce the search input to prevent unnecessary
                      // full widget tree and map list rebuilds on every single keystroke.
                      _debouncer.run(() {
                        setState(() => _shopQuery = value);
                      });
                    },
                    onSubmitted: _rememberSearch,
                    decoration: InputDecoration(
                      hintText: "Search shop name, service, or area",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: "Voice search",
                        onPressed: _showVoiceSearchPrompt,
                        icon: const Icon(Icons.mic_rounded),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDiscoveryFilters(visibleShops),
              ],
            ),
          ),
          if (!_isLoading && visibleShops.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: Colors.black54,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "No shops available right now.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          if (visibleShops.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: visibleShops.length,
                  itemBuilder: (context, index, realIndex) {
                    final shop = visibleShops[index];
                    return _buildShopCard(shop, seletedShopProvider);
                  },
                  options: CarouselOptions(
                    height: size.height * 0.38,
                    enlargeCenterPage: true,
                    viewportFraction: 0.85,
                    onPageChanged: (index, reason) {
                      final shop = visibleShops[index];
                      _goToLocation(shop.locationX, shop.locationY, 16);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShopCard(Shop shop, seletedShop seletedShopProvider) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shop.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_favoriteStoreIds.contains(shop.id))
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child:
                        Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorPalletsExtended.deepBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '₹${shop.cost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            RatingBarIndicator(
              rating: shop.avgRating.toDouble(),
              itemBuilder: (context, index) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 16,
            ),
            const SizedBox(height: 6),
            Text(
              shop.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildServiceChip('B/W'),
                _buildServiceChip('Color'),
                _buildServiceChip('Binding'),
                _buildServiceChip(_isShopOpenNow(shop) ? 'Open now' : 'Closed'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${shop.openingTime} - ${shop.closingTime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  shop.distance,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ColorPalletsExtended.deepBlue,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(
                    "https://www.google.com/maps/dir/?api=1&destination=${shop.locationX},${shop.locationY}&travelmode=driving",
                  );
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.navigation_outlined, size: 16),
                label: const Text("Open in Maps"),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  seletedShopProvider.setSeletedShop(shop);
                  Navigator.of(context).pushNamed(
                    CheckoutScreen.routeName,
                    arguments: widget.accessToken,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalletsExtended.deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Checkout', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryFilters(List<Shop> visibleShops) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Open now'),
                    selected: _openNowOnly,
                    onSelected: (value) => setState(() => _openNowOnly = value),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('4+ rating'),
                    selected: _rating4PlusOnly,
                    onSelected: (value) =>
                        setState(() => _rating4PlusOnly = value),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _serviceFilter,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('All services')),
                      DropdownMenuItem(value: 'black', child: Text('B/W')),
                      DropdownMenuItem(value: 'color', child: Text('Color')),
                      DropdownMenuItem(
                          value: 'binding', child: Text('Binding')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _serviceFilter = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text('Under ₹${_maxPrice.toInt()}'),
                ],
              ),
            ),
            Slider(
              value: _maxPrice,
              min: 20,
              max: 1000,
              divisions: 49,
              label: '₹${_maxPrice.toInt()}',
              onChanged: (value) => setState(() => _maxPrice = value),
            ),
            if (_recentSearches.isNotEmpty)
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentSearches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final recent = _recentSearches[index];
                    return ActionChip(
                      label: Text(recent),
                      onPressed: () {
                        _shopSearchController.text = recent;
                        _debouncer.cancel();
                        setState(() => _shopQuery = recent);
                      },
                    );
                  },
                ),
              ),
            Text(
              '${visibleShops.length} matching shop(s)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorPalletsExtended.deepBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ColorPalletsExtended.deepBlue,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _rememberSearch(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    setState(() {
      _recentSearches
        ..removeWhere((item) => item.toLowerCase() == text.toLowerCase())
        ..insert(0, text);
      if (_recentSearches.length > 6) _recentSearches.removeLast();
    });
  }

  void _showVoiceSearchPrompt() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Search'),
        content: const Text(
          'Tap the microphone on your keyboard and speak the shop, area, or service name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _isShopOpenNow(Shop shop) {
    final open = _parseHour(shop.openingTime);
    final close = _parseHour(shop.closingTime);
    if (open == null || close == null) return true;
    final now = TimeOfDay.now();
    final current = now.hour * 60 + now.minute;
    if (close < open) {
      return current >= open || current <= close;
    }
    return current >= open && current <= close;
  }

  int? _parseHour(String raw) {
    final lower = raw.trim().toLowerCase();
    final match =
        RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(lower);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (hour == null) return null;
    final period = match.group(3);
    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  String _serviceText(Shop shop) {
    return '${shop.costBlack} ${shop.costColor} ${shop.spiralBinding} ${shop.staplesBinding} ${shop.stickFile} black color binding';
  }
}
