import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/map_service.dart';
import "../../model/auto_complete_result.dart";
import '../../providers/current_user.dart';
import '../../providers/search_place.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';
import '../../utils/pill_notifications.dart';

class BuildListTile extends StatefulWidget {
  final AutoCompleteResult item;
  final BuildContext ctx;
  final ValueNotifier<bool>? isLoadingTextPage;
  const BuildListTile(
      {super.key,
      required this.item,
      required this.ctx,
      required this.isLoadingTextPage});

  @override
  State<BuildListTile> createState() => _BuildListTileState();
}

class _BuildListTileState extends State<BuildListTile> {
  @override
  Widget build(BuildContext context) {
    final curUser = Provider.of<CurrentUser>(context, listen: false);
    final autoComple = Provider.of<PlaceResult>(context, listen: false);
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;

    return GestureDetector(
      onTap: () async {
        widget.isLoadingTextPage?.value = true;
        FocusScope.of(context).unfocus();
        try {
          var res = await MapServices()
              .getPlaceDetails(widget.item.placeId.toString());
          final geometry = res["geometry"] as Map<String, dynamic>?;
          final location = geometry?["location"] as Map<String, dynamic>?;
          final lat = (location?["lat"] as num?)?.toDouble();
          final lng = (location?["lng"] as num?)?.toDouble();
          if (lat == null || lng == null) {
            throw Exception("Could not parse selected location.");
          }
          curUser.updateUserLocation(lat, lng);
          curUser.updateUserPlaceName(
              widget.item.structuredFormatting!.mainText.toString());
          curUser.updateUserCountry("India");
          List<AutoCompleteResult> emptyList = [];
          autoComple.setResult(emptyList);
          if (!context.mounted) return;
          // Close only search sheet/screen, do not collapse the full navigation
          // stack (this was breaking map selection flow in store creator).
          final navigator = Navigator.maybeOf(context);
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          }
          autoComple.allreturnedResult = [];
        } catch (_) {
          if (!context.mounted) return;
          PillNotifications.show(
            context,
            message: "Map location lookup failed. Check Google Maps API setup.",
            type: PillType.error,
          );
        } finally {
          widget.isLoadingTextPage?.value = false;
        }
      },
      child: Container(
          margin: EdgeInsets.symmetric(
              vertical: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 10,
              ),
              horizontal: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 5,
              )),
          padding: EdgeInsets.only(
              bottom: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 15,
              ),
              right: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 10,
              ),
              top: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 15,
              ),
              left: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 30,
              )),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 40,
                    ),
                    color: ColorPallets.deepBlue,
                  ),
                  SizedBox(
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 50,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          widget.item.structuredFormatting!.mainText.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: ColorPallets.deepBlue,
                              fontSize: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 35,
                              )),
                        ),
                        SizedBox(
                          height: calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 8,
                          ),
                        ),
                        Text(
                          widget.item.structuredFormatting!.secondaryText
                              .toString(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ColorPallets.deepBlue,
                            fontSize: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 27,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              Divider(
                thickness: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 2,
                ),
              ),
            ],
          )),
    );
  }
}
