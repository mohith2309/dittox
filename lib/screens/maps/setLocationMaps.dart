import "dart:async";

import "package:dittox/screens/maps/textLocation.dart";
import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:provider/provider.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";

import '../../helpers/user_location.dart';
import '../../utils/location_history_store.dart';
import "../../providers/current_user.dart";
import "../../utils/color_pallets.dart";
import "../../utils/dynamicSizing.dart";
import "../../utils/pill_notifications.dart";
import '../../widgets/IconButton.dart';

class SetLocationMaps extends StatefulWidget {
  const SetLocationMaps({super.key});
  static const routeName = "/setLocationMaps";
  @override
  State<SetLocationMaps> createState() => _SetLocationMapsState();
}

// Backward compatibility for older references still using lowercase class name.
class setLocationMaps extends SetLocationMaps {
  const setLocationMaps({super.key});
}

class _SetLocationMapsState extends State<SetLocationMaps> {
  final Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor? mapMaker;
  bool isLoading = false;
  bool _didCenterInitialLocation = false;
  bool _locationConfirmed = false;
  Set<Marker> _markers = {};
  double? _pendingLat;
  double? _pendingLng;

  @override
  void initState() {
    super.initState();
    setCustomMarker();
  }

  void setCustomMarker() async {
    mapMaker = await BitmapDescriptor.asset(
        const ImageConfiguration(), "assets/image/pin_gif.gif");
  }

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  Future<void> goToSearchedPlace(double lat, double lng, double zooms) async {
    setState(() => isLoading = true);
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: zooms,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );
    if (mounted) setState(() => isLoading = false);
  }

  void setMarkers(double lat, double lng) {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId("marker $lat $lng"),
          position: LatLng(lat, lng),
          onTap: () async => await goToSearchedPlace(lat, lng, 16.5),
          icon: BitmapDescriptor.defaultMarker,
          draggable: true,
        )
      };
    });
  }

  Future<void> goToProviderLocation(CurrentUser curUser, double zooms) async {
    setState(() => isLoading = true);
    await goToSearchedPlace(curUser.latitude, curUser.longitude, zooms);
    setMarkers(curUser.latitude, curUser.longitude);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> updateOnTapLocation(
      CurrentUser curUser, LatLng location, double zooms) async {
    try {
      setState(() {
        isLoading = true;
        _pendingLat = location.latitude;
        _pendingLng = location.longitude;
      });
      final userPlaceMark = await UserLocation.getUserPlaceMarks(
          location.latitude, location.longitude);
      await goToSearchedPlace(location.latitude, location.longitude, zooms);
      setMarkers(location.latitude, location.longitude);
      curUser.updateUserLocation(location.latitude, location.longitude);
      curUser.updateUserPlaceName(userPlaceMark["locality"] ?? "");
      curUser.updateUserCountry(userPlaceMark["country"] ?? "");
      _locationConfirmed = true;
    } catch (_) {
      if (!mounted) return;
      PillNotifications.show(
        context,
        message: "Unable to update selected location.",
        type: PillType.error,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> goToCurrentLocation(CurrentUser curUser, double zooms) async {
    try {
      setState(() => isLoading = true);
      final position = await UserLocation.getUserLatLong();
      final userPlaceMark = await UserLocation.getUserPlaceMarks(
          position.latitude, position.longitude);
      await goToSearchedPlace(position.latitude, position.longitude, zooms);
      setMarkers(position.latitude, position.longitude);
      curUser.updateUserLocation(position.latitude, position.longitude);
      curUser.updateUserPlaceName(userPlaceMark["locality"] ?? "");
      curUser.updateUserCountry(userPlaceMark["country"] ?? "");
    } catch (_) {
      if (!mounted) return;
      PillNotifications.show(
        context,
        message: "Unable to fetch current location.",
        type: PillType.error,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final curUser = context.watch<CurrentUser>();
    final placeName = context.select((CurrentUser u) => u.placeName);
    final countryName = context.select((CurrentUser u) => u.userCountryName);

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: size.height,
            width: size.width,
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              mapType: MapType.normal,
              onMapCreated: (controller) {
                _controller.complete(controller);
                if (!_didCenterInitialLocation) {
                  _didCenterInitialLocation = true;
                  goToProviderLocation(curUser, 16);
                }
              },
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              onTap: (val) => updateOnTapLocation(curUser, val, 18),
              markers: _markers,
            ),
          ),
          Positioned(
            right: 16,
            bottom: size.height * 0.36,
            child: GestureDetector(
              onTap: () => goToCurrentLocation(curUser, 18),
              child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPallets.swiggyOrange.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(
                        calculateDynamicFontSize(
                            totalScreenHeight: size.height,
                            totalScreenWidth: size.width,
                            currentFontSize: 50)),
                    boxShadow: [
                      BoxShadow(
                          color:
                              ColorPallets.swiggyOrange.withValues(alpha: 0.6),
                          blurRadius: 10)
                    ],
                  ),
                  height: 50,
                  width: 170,
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                        "Current Location",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                    ],
                  )),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                  color: ColorPallets.deepBlue.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                        color: ColorPallets.deepBlue.withValues(alpha: 1),
                        blurRadius: 30)
                  ]),
              constraints: BoxConstraints(
                minHeight: 180,
                maxHeight: size.height * 0.34,
              ),
              width: size.width,
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : Column(children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      placeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(LocationText.routeName),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Text(
                                        "Change",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "$placeName, $countryName",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (_locationConfirmed &&
                              _pendingLat != null &&
                              _pendingLng != null) {
                            final userMap = curUser.userMap;
                            userMap['latitude'] = _pendingLat;
                            userMap['longitude'] = _pendingLng;
                            await LocationHistoryStore.addLocation(
                              placeName: placeName,
                              latitude: _pendingLat!,
                              longitude: _pendingLng!,
                              country: countryName,
                            );
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 56,
                          width: double.infinity,
                          color: ColorPallets.swiggyOrange,
                          child: const Center(
                            child: Text(
                              "Confirm",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      )
                    ]),
            ),
          ),
          Positioned(
              left: 50,
              top: 80,
              child: CustomIconButton(
                semanticLabel: "Back",
                onPressed: () async {
                  if (_locationConfirmed &&
                      _pendingLat != null &&
                      _pendingLng != null) {
                    final userMap = curUser.userMap;
                    userMap['latitude'] = _pendingLat;
                    userMap['longitude'] = _pendingLng;
                    await LocationHistoryStore.addLocation(
                      placeName: placeName,
                      latitude: _pendingLat!,
                      longitude: _pendingLng!,
                      country: countryName,
                    );
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: FontAwesomeIcons.chevronLeft,
                iconColor: ColorPallets.white,
                backGroundColor: ColorPallets.deepBlue,
                size: 80,
                iconSize: 40,
              ))
        ],
      ),
    );
  }
}
