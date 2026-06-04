import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helpers/sqlLite.dart';
import "../model/user.dart";

class CurrentUser with ChangeNotifier {
  static const _defaultLat = 12.9716;
  static const _defaultLng = 77.5946;
  
  Users _currentUser = Users(
    userId: "Loading...",
    userName: "Loading...",
    userEmail: "Loading...",
    userPlaceName: "Bangalore",
    latitude: _defaultLat,
    longitude: _defaultLng,
    userPhoneNumber: "",
    userContryName: "India",
    userAccessToken: "",
  );

  void initCurrentUser(String id, String accessToken, double lat, double lng) async {
    final userMap = await SQLHelpers.getUserById(id);
    _currentUser = Users(
      userId: userMap["userId"],
      userName: userMap["userName"],
      userEmail: userMap["userEmail"],
      userPlaceName: userMap["userPlaceName"],
      latitude: lat,
      longitude: lng,
      userPhoneNumber: userMap["userPhoneNumber"],
      userContryName: userMap["userContryName"],
      userAccessToken: accessToken,
    );

    await SQLHelpers.updateUserAccessToken(id, accessToken);
    notifyListeners();
  }

  void initDemoUser() {
    _currentUser = Users(
      userId: "demo_user",
      userName: "Demo User",
      userEmail: "demo@dittox.in",
      userPlaceName: "Bangalore",
      latitude: _defaultLat,
      longitude: _defaultLng,
      userPhoneNumber: "0000000000",
      userContryName: "India",
      userAccessToken: "demo_token",
    );
    notifyListeners();
  }

  String get userAccessToken => _currentUser.userAccessToken;
  String get userId => _currentUser.userId;
  String get userName => _currentUser.userName;
  String get userEmail => _currentUser.userEmail;
  String get placeName => _currentUser.userPlaceName;
  double get latitude => _currentUser.latitude;
  double get longitude => _currentUser.longitude;
  String get userPhoneNumber => _currentUser.userPhoneNumber;
  String get userCountryName => _currentUser.userContryName;

  // Aliases for missing getters
  String get getUserName => userName;
  String get getUserEmail => userEmail;
  String get getUserPhoneNumber => userPhoneNumber;
  String get getPlaceName => placeName;
  double get getUsetLatitude => latitude;
  double get getUserLongitude => longitude;
  String get getUserContryName => userCountryName;

  void setCurrentUser(Users user) {
    _currentUser = user;
    SQLHelpers.insertUser(user);
    notifyListeners();
  }

  Future<void> loadLatestUser() async {
    final latestUser = await SQLHelpers.getLatestUser("users");
    if (latestUser.isNotEmpty) {
      _currentUser = Users(
        userId: latestUser["userId"],
        userName: latestUser["userName"],
        userEmail: latestUser["userEmail"],
        userPlaceName: latestUser["userPlaceName"],
        latitude: latestUser["latitude"],
        longitude: latestUser["longitude"],
        userPhoneNumber: latestUser["userPhoneNumber"],
        userContryName: latestUser["userContryName"],
        userAccessToken: latestUser["userAccessToken"],
      );
      notifyListeners();
    }
  }

  Future<void> loadUserByAccessToken(String accessToken) async {
    if (accessToken.trim().isEmpty || accessToken == "demo_token") {
      return;
    }

    Map<String, dynamic> idUserMap =
        await SQLHelpers.getUserByAccessToken(accessToken);

    // Firebase ID token can rotate; fallback to lookup by current Firebase uid.
    if (idUserMap.isEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        idUserMap = await SQLHelpers.getUserById(uid);
      }
    }

    if (idUserMap.isEmpty) return;

    final userId = idUserMap["userId"]?.toString() ?? "";
    final userName = idUserMap["userName"]?.toString() ?? "User";
    final userEmail = idUserMap["userEmail"]?.toString() ??
        idUserMap["email"]?.toString() ??
        "";
    final userPhone = idUserMap["userPhoneNumber"]?.toString() ?? "";

    final lat = (idUserMap["latitude"] as num?)?.toDouble() ?? _defaultLat;
    final lng = (idUserMap["longitude"] as num?)?.toDouble() ?? _defaultLng;
    final locality = idUserMap["userPlaceName"]?.toString() ?? "Bangalore";
    final country = idUserMap["userContryName"]?.toString() ?? "India";

    _currentUser = Users(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPlaceName: locality,
      latitude: lat,
      longitude: lng,
      userContryName: country,
      userPhoneNumber: userPhone,
      userAccessToken: accessToken,
    );
    notifyListeners();
  }

  // Updated setters to maintain consistency with old interface
  void updateUserName(String name) { _currentUser.userName = name; SQLHelpers.insertUser(_currentUser); notifyListeners(); }
  void updateUserEmail(String email) { _currentUser.userEmail = email; SQLHelpers.insertUser(_currentUser); notifyListeners(); }
  void updateUserPlaceName(String placeName) { _currentUser.userPlaceName = placeName; SQLHelpers.insertUser(_currentUser); notifyListeners(); }
  void updateUserLocation(double lat, double lng) { _currentUser.latitude = lat; _currentUser.longitude = lng; notifyListeners(); }
  void updateUserPhoneNumber(String phone) { _currentUser.userPhoneNumber = phone; SQLHelpers.insertUser(_currentUser); notifyListeners(); }
  void updateUserCountry(String country) { _currentUser.userContryName = country; SQLHelpers.insertUser(_currentUser); notifyListeners(); }

  // Aliases for missing setters
  void setUserName(String name) => updateUserName(name);
  void setUserEmail(String email) => updateUserEmail(email);
  void setUserPlaceName(String name) => updateUserPlaceName(name);
  void setUserLatitudeLogitude(double lat, double lng) => updateUserLocation(lat, lng);
  void setUserContryName(String name) => updateUserCountry(name);

  Map<String, dynamic> get userMap => _currentUser.toMap;
  Map<String, dynamic> get getCurrentUserMap => userMap;
}
