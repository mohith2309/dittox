import 'package:flutter/material.dart';

import '../model/shop.dart';

class seletedShop extends ChangeNotifier {
  late Shop userSeletedShop;

  void setSeletedShop(Shop shop) {
    userSeletedShop = shop;
    notifyListeners();
  }

  Shop getSeletedShop() {
    return userSeletedShop;
  }

  void printSeletedShop() {
    debugPrint(userSeletedShop.toMap.toString());
  }

  Map<String, String> shopOrderPreview() {
    return {
      "shopName": userSeletedShop.storeName,
      "contactNumber": userSeletedShop.contactNumber,
      "shopEmail": userSeletedShop.email,
      "distance": userSeletedShop.distance,
      "duration": userSeletedShop.duration,
      "rating": userSeletedShop.avgRating.toString(),
      "shopAddress": userSeletedShop.address,
      "price": userSeletedShop.cost.toString(),
    };
  }
}
