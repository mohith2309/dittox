import "dart:async";

import "package:flutter/material.dart";
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import "package:provider/provider.dart";

import '../../helpers/map_service.dart';
import '../../providers/search_place.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';
import '../../utils/app_optimizations.dart';
import '../../widgets/maps/buildListTile.dart';

class LocationText extends StatefulWidget {
  static const routeName = "/locationText";
  const LocationText({super.key});

  @override
  State<LocationText> createState() => _LocationTextState();
}

class _LocationTextState extends State<LocationText> {
  var placesSearchController = TextEditingController();
  final ValueNotifier<bool> isLoadingTextPage = ValueNotifier<bool>(false);
  // Bolt: Use shared Debouncer for memory efficiency and accurate cancellation
  final Debouncer _debouncer = Debouncer(milliseconds: 320);

  @override
  void dispose() {
    isLoadingTextPage.dispose();
    placesSearchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PlaceResult placeProvider = Provider.of<PlaceResult>(context, listen: true);
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Enter Location!",
          ),
        ),
        body: Container(
          // margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          margin: EdgeInsets.symmetric(
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
          // padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              TextField(
                autofocus: true,
                showCursor: true,
                cursorHeight: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 50,
                  // heightSpecific: true,
                ),
                cursorWidth: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 5,
                  // heightSpecific: false,,
                ),
                cursorColor: ColorPallets.deepBlue,
                controller: placesSearchController,
                style: TextStyle(
                  // fontSize: 18,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ),
                  color: ColorPallets.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: "Search by Locality , PinCode or Area",
                  // hintStyle: TextStyle(
                  //   color: ColorPallets.deepBlue,
                  //   fontWeight: FontWeight.w500,
                  //   // fontSize: 16,
                  //   fontSize: calculateDynamicFontSize(
                  //     totalScreenHeight: totalScreenHeight,
                  //     totalScreenWidth: totalScreenWidth,
                  //     currentFontSize: 16,
                  //     // heightSpecific: true,
                  //   ),
                  // ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: placesSearchController.text.isEmpty
                      ? const SizedBox(
                          width: 0,
                        )
                      : Padding(
                          padding: EdgeInsets.only(
                            // top: 10,
                            top: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 40,
                              // heightSpecific: true,
                            ),
                          ),
                          child: IconButton(
                              color: ColorPallets.swiggyOrange,
                              onPressed: () {
                                // Bolt: Cancel pending debouncer before synchronous state update
                                _debouncer.cancel();
                                placesSearchController.clear();
                                placeProvider.setResult([]);
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.xmark,
                                // size: 18,
                                size: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 40,
                                  // heightSpecific: true,
                                ),
                              )),
                        ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _debouncer.run(() async {
                    final query = value.trim();
                    if (query.length <= 2) {
                      placeProvider.setResult([]);
                      return;
                    }
                    try {
                      final searchResults =
                          await MapServices().searchPlace(query);
                      if (!mounted) return;
                      placeProvider.setResult(searchResults);
                    } catch (_) {
                      if (!mounted) return;
                      placeProvider.setResult([]);
                    }
                  });
                },
              ),
              isLoadingTextPage.value
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : placeProvider.allreturnedResult.isNotEmpty
                      ? Expanded(
                          child: SizedBox(
                            // Bolt: Use EfficientListView to lazily build search result items
                            child: EfficientListView(
                              itemCount: placeProvider.allreturnedResult.length,
                              itemBuilder: (context, index) {
                                return BuildListTile(
                                  item: placeProvider.allreturnedResult[index],
                                  ctx: context,
                                  isLoadingTextPage: isLoadingTextPage,
                                );
                              },
                            ),
                          ),
                        )
                      : Expanded(
                          child: Center(
                            child: Text(
                              "No Results .... yet",
                              style: TextStyle(
                                // fontSize: 26,
                                fontSize: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 60,
                                  // heightSpecific: true,
                                ),
                              ),
                            ),
                          ),
                        ),
            ],
          ),
        ));
  }
}
