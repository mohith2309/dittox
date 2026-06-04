import 'package:shared_preferences/shared_preferences.dart';

class CouponCode {
  final String code;
  final String description;
  final int discountPercent;
  final int maxUses;
  final int minOrderAmount;
  final bool isEasterEgg;
  final String? easterEggMessage;
  final String? easterEggEmoji;

  const CouponCode({
    required this.code,
    required this.description,
    required this.discountPercent,
    this.maxUses = 100,
    this.minOrderAmount = 0,
    this.isEasterEgg = false,
    this.easterEggMessage,
    this.easterEggEmoji,
  });
}

class CouponSystem {
  static const String _usageCountKey = 'dittox_coupon_usage_count';

  static const List<CouponCode> _couponCodes = [
    CouponCode(
      code: 'DITTOX10',
      description: '10% off on first order',
      discountPercent: 10,
      maxUses: 1000,
      minOrderAmount: 100,
    ),
    CouponCode(
      code: 'SAVE20',
      description: '20% off on orders above ₹300',
      discountPercent: 20,
      maxUses: 500,
      minOrderAmount: 300,
    ),
    CouponCode(
      code: 'FIRST50',
      description: 'Flat ₹50 off',
      discountPercent: 0,
      maxUses: 200,
      minOrderAmount: 200,
      isEasterEgg: true,
      easterEggMessage: '🎉 First time user discount!',
      easterEggEmoji: '🥳',
    ),
    CouponCode(
      code: 'BHOOOO',
      description: '👻 Spooky discount!',
      discountPercent: 15,
      maxUses: 100,
      minOrderAmount: 150,
      isEasterEgg: true,
      easterEggMessage: '🎃 BHOOOO! You found the ghost! 15% off!',
      easterEggEmoji: '👻',
    ),
    CouponCode(
      code: 'MOHITGIFT',
      description: "Mohit's special gift 💝",
      discountPercent: 50,
      maxUses: 1,
      minOrderAmount: 500,
      isEasterEgg: true,
      easterEggMessage: '🎁 Special gift from Mohit! 50% off - you\'re special!',
      easterEggEmoji: '💝',
    ),
    CouponCode(
      code: 'DURGAVARA',
      description: 'For the legends 🔥',
      discountPercent: 25,
      maxUses: 10,
      minOrderAmount: 200,
      isEasterEgg: true,
      easterEggMessage: '🔥 LEGEND ALERT! Durgavara say hi! 25% off!',
      easterEggEmoji: '🔥',
    ),
    CouponCode(
      code: 'KONNICHIWA',
      description: 'Japanese discount! 🇯🇵',
      discountPercent: 30,
      maxUses: 50,
      minOrderAmount: 250,
      isEasterEgg: true,
      easterEggMessage: '🇯🇵 Konichiwa! 30% off coming through!',
      easterEggEmoji: '🍣',
    ),
    CouponCode(
      code: 'SUPERUSER',
      description: 'Admin access granted ⚡',
      discountPercent: 100,
      maxUses: 1,
      minOrderAmount: 0,
      isEasterEgg: true,
      easterEggMessage: '⚡ SUPERUSER DETECTED! FREE ORDER!',
      easterEggEmoji: '⚡',
    ),
    CouponCode(
      code: 'TADA🎉',
      description: 'Surprise! 🎊',
      discountPercent: 35,
      maxUses: 25,
      minOrderAmount: 200,
      isEasterEgg: true,
      easterEggMessage: '🎊 TADA! You found a surprise! 35% off!',
      easterEggEmoji: '🎉',
    ),
    CouponCode(
      code: 'SECRET42',
      description: 'The answer to everything',
      discountPercent: 42,
      maxUses: 42,
      minOrderAmount: 42,
      isEasterEgg: true,
      easterEggMessage: '🌀 The answer is 42! And 42% off!',
      easterEggEmoji: '🌀',
    ),
    CouponCode(
      code: 'HELLO',
      description: 'A simple greeting 👋',
      discountPercent: 5,
      maxUses: 100,
      minOrderAmount: 50,
      isEasterEgg: true,
      easterEggMessage: '👋 Hello! 5% off for saying hello!',
      easterEggEmoji: '👋',
    ),
    CouponCode(
      code: 'MAGIC🪄',
      description: 'Magic discount! ✨',
      discountPercent: 40,
      maxUses: 20,
      minOrderAmount: 300,
      isEasterEgg: true,
      easterEggMessage: '✨✨ MAGIC! 40% off - Abracadabra! ✨✨',
      easterEggEmoji: '🪄',
    ),
    CouponCode(
      code: 'ROCKET🚀',
      description: 'Blast off! 🚀',
      discountPercent: 33,
      maxUses: 33,
      minOrderAmount: 200,
      isEasterEgg: true,
      easterEggMessage: '🚀 BLAST OFF! 33% off - To the moon! 🌙',
      easterEggEmoji: '🚀',
    ),
    CouponCode(
      code: 'GAMING🎮',
      description: 'Gamer discount! 🎮',
      discountPercent: 28,
      maxUses: 100,
      minOrderAmount: 250,
      isEasterEgg: true,
      easterEggMessage: '🎮 GG! 28% off - Level up your printing! 🎮',
      easterEggEmoji: '🎮',
    ),
    CouponCode(
      code: 'CODER💻',
      description: 'For developers! 💻',
      discountPercent: 45,
      maxUses: 50,
      minOrderAmount: 150,
      isEasterEgg: true,
      easterEggMessage: '💻 Hello, World! 45% off - Compile success!',
      easterEggEmoji: '💻',
    ),
    CouponCode(
      code: 'LOVE❤️',
      description: 'Love is in the air 💕',
      discountPercent: 22,
      maxUses: 100,
      minOrderAmount: 100,
      isEasterEgg: true,
      easterEggMessage: '❤️ Love you! 22% off - Spread the love! 💕',
      easterEggEmoji: '❤️',
    ),
    CouponCode(
      code: 'CHILL😎',
      description: 'Chill mode activated 🌴',
      discountPercent: 18,
      maxUses: 75,
      minOrderAmount: 150,
      isEasterEgg: true,
      easterEggMessage: '😎 Chill vibes only! 18% off - No stress! 🌴',
      easterEggEmoji: '😎',
    ),
  ];

  static List<CouponCode> getAllCoupons() => _couponCodes;

  static List<CouponCode> getEasterEggCoupons() =>
      _couponCodes.where((c) => c.isEasterEgg).toList();

  static List<CouponCode> getNormalCoupons() =>
      _couponCodes.where((c) => !c.isEasterEgg).toList();

  static Future<CouponResult> validateCoupon(String code, double orderAmount) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final upperCode = code.trim().toUpperCase();
    final coupon = _couponCodes.firstWhere(
      (c) => c.code.toUpperCase() == upperCode,
      orElse: () => const CouponCode(
        code: '',
        description: '',
        discountPercent: 0,
      ),
    );

    if (coupon.code.isEmpty) {
      return const CouponResult(
        isValid: false,
        message: 'Invalid coupon code',
        discountPercent: 0,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final usageCount = prefs.getInt('${_usageCountKey}_$upperCode') ?? 0;

    if (usageCount >= coupon.maxUses) {
      return const CouponResult(
        isValid: false,
        message: 'Coupon expired or max uses reached',
        discountPercent: 0,
      );
    }

    if (orderAmount < coupon.minOrderAmount) {
      return CouponResult(
        isValid: false,
        message: 'Minimum order amount ₹${coupon.minOrderAmount} required',
        discountPercent: 0,
      );
    }

    return CouponResult(
      isValid: true,
      message: coupon.description,
      discountPercent: coupon.discountPercent,
      discountAmount: coupon.discountPercent > 0
          ? (orderAmount * coupon.discountPercent / 100)
          : 50,
      easterEggMessage: coupon.isEasterEgg ? coupon.easterEggMessage : null,
      easterEggEmoji: coupon.isEasterEgg ? coupon.easterEggEmoji : null,
    );
  }

  static Future<void> markCouponUsed(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final upperCode = code.trim().toUpperCase();
    final current = prefs.getInt('${_usageCountKey}_$upperCode') ?? 0;
    await prefs.setInt('${_usageCountKey}_$upperCode', current + 1);
  }
}

class CouponResult {
  final bool isValid;
  final String message;
  final int discountPercent;
  final double discountAmount;
  final String? easterEggMessage;
  final String? easterEggEmoji;

  const CouponResult({
    required this.isValid,
    required this.message,
    required this.discountPercent,
    this.discountAmount = 0,
    this.easterEggMessage,
    this.easterEggEmoji,
  });
}
