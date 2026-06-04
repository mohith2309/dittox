import '../model/shop.dart';

/// Default/fallback shop data used when Firestore shop_profiles is empty.
/// In production these are overridden by real shops from Firestore.
class DemoData {
  /// Default shops used as a fallback when Firestore is unavailable.
  static List<Shop> getDefaultShops() {
    return [
      Shop(
        id: 'default_shop_1',
        name: 'QuickPrint — MG Road',
        storeName: 'QuickPrint',
        address: 'MG Road, Bangalore - 560001',
        locationX: 12.9716,
        locationY: 77.5946,
        avgRating: 4.5,
        openingTime: '09:00',
        closingTime: '21:00',
        costOneSide: '1.0',
        costTwoSide: '1.5',
        costBlack: '2.0',
        costColor: '10.0',
        sizeA4: '0.5',
        sizeA5: '0.3',
        legal: '1.0',
        letter: '0.5',
        sizeB5: '0.4',
        sizeA6: '0.2',
        postCard: '2.0',
        size5X7: '3.0',
        size4X6: '2.5',
        size35X5: '1.0',
        spiralBinding: '30.0',
        staplesBinding: '5.0',
        stickFile: '10.0',
        bondPage: '5.0',
        quality100Gsm: '5.0',
        quality80gsm: '3.0',
        distance: '',
        duration: '',
        email: 'support@dittox.in',
        contactNumber: '',
      ),
      Shop(
        id: 'default_shop_2',
        name: 'DigitalPrints — Koramangala',
        storeName: 'DigitalPrints',
        address: 'Koramangala, Bangalore - 560034',
        locationX: 12.9352,
        locationY: 77.6245,
        avgRating: 4.8,
        openingTime: '08:00',
        closingTime: '22:00',
        costOneSide: '0.8',
        costTwoSide: '1.2',
        costBlack: '1.5',
        costColor: '8.0',
        sizeA4: '0.4',
        sizeA5: '0.25',
        legal: '0.8',
        letter: '0.4',
        sizeB5: '0.35',
        sizeA6: '0.15',
        postCard: '1.5',
        size5X7: '2.5',
        size4X6: '2.0',
        size35X5: '0.8',
        spiralBinding: '25.0',
        staplesBinding: '4.0',
        stickFile: '8.0',
        bondPage: '4.0',
        quality100Gsm: '4.0',
        quality80gsm: '2.5',
        distance: '',
        duration: '',
        email: 'support@dittox.in',
        contactNumber: '',
      ),
      Shop(
        id: 'default_shop_3',
        name: 'ExpressPrints — Indiranagar',
        storeName: 'ExpressPrints',
        address: '100 Feet Road, Indiranagar, Bangalore - 560038',
        locationX: 12.9784,
        locationY: 77.6408,
        avgRating: 4.2,
        openingTime: '10:00',
        closingTime: '20:00',
        costOneSide: '1.2',
        costTwoSide: '1.8',
        costBlack: '2.5',
        costColor: '12.0',
        sizeA4: '0.6',
        sizeA5: '0.35',
        legal: '1.2',
        letter: '0.6',
        sizeB5: '0.5',
        sizeA6: '0.25',
        postCard: '2.5',
        size5X7: '3.5',
        size4X6: '3.0',
        size35X5: '1.2',
        spiralBinding: '35.0',
        staplesBinding: '6.0',
        stickFile: '12.0',
        bondPage: '6.0',
        quality100Gsm: '6.0',
        quality80gsm: '4.0',
        distance: '',
        duration: '',
        email: 'support@dittox.in',
        contactNumber: '',
      ),
    ];
  }

  /// Check if running in demo/test mode
  static bool isDemoMode(String? accessToken) {
    return accessToken == 'demo_token' || accessToken == 'demo';
  }

  /// Mock payment response for fallback mode
  static Map<String, dynamic> getMockPaymentResponse(String orderId) {
    return {
      'responseCode': 'OK',
      'message': 'Payment recorded locally',
      'result': {
        'orderId': orderId,
        'paymentId': 'local_pay_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'completed',
        'amount': 0,
        'timestamp': DateTime.now().toIso8601String(),
      }
    };
  }

  /// Mock order creation response for fallback mode
  static Map<String, dynamic> getMockOrderResponse() {
    final orderId = 'local_order_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'responseCode': 'OK',
      'message': 'Order created locally',
      'result': {
        'orderId': orderId,
        'amount': 0,
        'currency': 'INR',
        'status': 'created',
      }
    };
  }
}
