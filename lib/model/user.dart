class Users {
  String userName;
  String userId;
  String userEmail;
  String userPlaceName;
  double latitude;
  double longitude;
  String userContryName;
  String userPhoneNumber;
  String userAccessToken;

  Users({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPlaceName,
    required this.latitude,
    required this.longitude,
    required this.userPhoneNumber,
    required this.userContryName,
    required this.userAccessToken,
  });

  Map<String, dynamic> get toMap {
    return {
      "userId": userId,
      "userName": userName,
      "userEmail": userEmail,
      "userPlaceName": userPlaceName,
      "latitude": latitude,
      "longitude": longitude,
      "userPhoneNumber": userPhoneNumber,
      "userContryName": userContryName,
      "userAccessToken": userAccessToken,
    };
  }
}
