import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_sync_guard.dart';

class StoreAuthStore {
  static const String _kStores = "dittox_store_accounts_v1";
  static const String _kActiveStore = "dittox_active_store_v1";

  static Future<List<Map<String, dynamic>>> _getStores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStores);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> _setStores(List<Map<String, dynamic>> stores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStores, jsonEncode(stores));
  }

  static Future<void> _ensureFirebaseSession({
    required String email,
    required String password,
    bool createIfMissing = true,
  }) async {
    final auth = FirebaseAuth.instance;
    final mail = email.trim().toLowerCase();
    final pass = password.trim();
    if (mail.isEmpty || pass.length < 6) return;
    final currentMail = auth.currentUser?.email?.trim().toLowerCase();
    if (currentMail == mail) return;

    try {
      await auth.signInWithEmailAndPassword(email: mail, password: pass);
    } on FirebaseAuthException catch (error) {
      if (createIfMissing && error.code == 'user-not-found') {
        try {
          await auth.createUserWithEmailAndPassword(
              email: mail, password: pass);
        } catch (_) {}
      }
    } catch (_) {}
  }

  static Future<String?> registerStore({
    required String storeName,
    required String ownerName,
    required String phoneNumber,
    required String email,
    required String password,
    required String storeAddress,
    required String openingTime,
    required String closingTime,
    required String bankAccountNumber,
    required String ifscCode,
    required String upiId,
    required String linkedStoreId,
    required double latitude,
    required double longitude,
  }) async {
    final name = storeName.trim();
    final owner = ownerName.trim();
    final phone = phoneNumber.trim();
    final mail = email.trim().toLowerCase();
    final pass = password.trim();
    final address = storeAddress.trim();
    final open = openingTime.trim();
    final close = closingTime.trim();
    final bankAccount = bankAccountNumber.trim();
    final ifsc = ifscCode.trim().toUpperCase();
    final upi = upiId.trim().toLowerCase();
    final accountId = "store_${DateTime.now().millisecondsSinceEpoch}";
    final storeId =
        linkedStoreId.trim().isEmpty ? accountId : linkedStoreId.trim();

    if (name.isEmpty ||
        owner.isEmpty ||
        phone.length < 10 ||
        mail.isEmpty ||
        pass.length < 6 ||
        address.isEmpty ||
        open.isEmpty ||
        close.isEmpty ||
        bankAccount.length < 9 ||
        ifsc.length < 6 ||
        !upi.contains("@")) {
      return "Enter all store details (phone min 10 digits, password min 6 chars, valid UPI).";
    }

    final stores = await _getStores();
    final exists =
        stores.any((s) => (s["email"] ?? "").toString().toLowerCase() == mail);
    if (exists) return "Store email already exists.";

    final account = {
      "id": accountId,
      "storeName": name,
      "ownerName": owner,
      "phoneNumber": phone,
      "email": mail,
      "password": pass,
      "storeAddress": address,
      "openingTime": open,
      "closingTime": close,
      "bankAccountNumber": bankAccount,
      "ifscCode": ifsc,
      "upiId": upi,
      "linkedStoreId": storeId,
      "latitude": latitude,
      "longitude": longitude,
      "createdAt": DateTime.now().toIso8601String(),
    };

    stores.add(account);
    await _setStores(stores);

    await _ensureFirebaseSession(email: mail, password: pass);

    await CloudSyncGuard.runOptionalWrite(() async {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final updatedAt = DateTime.now().toIso8601String();

      batch.set(
        db.collection("stores").doc(account["id"]!.toString()),
        {
          ...account,
          "updatedAt": updatedAt,
        },
        SetOptions(merge: true),
      );

      batch.set(
        db.collection("shop_profiles").doc(storeId),
        {
          "name": name,
          "storeName": name,
          "address": address,
          "locationX": latitude == 0 ? 12.9716 : latitude,
          "locationY": longitude == 0 ? 77.5946 : longitude,
          "email": mail,
          "contactNumber": phone,
          "openingTime": open,
          "closingTime": close,
          "avgRating": 4.5,
          "isActive": true,
          "ownerStoreAccountId": accountId,
          "costOneSide": "1.0",
          "costTwoSide": "1.5",
          "costBlack": "2.0",
          "costColor": "10.0",
          "sizeA4": "0.5",
          "sizeA5": "0.3",
          "legal": "1.0",
          "letter": "0.5",
          "sizeB5": "0.4",
          "sizeA6": "0.2",
          "postCard": "2.0",
          "size5X7": "3.0",
          "size4X6": "2.5",
          "size35X5": "1.0",
          "spiralBinding": "30.0",
          "staplesBinding": "5.0",
          "stickFile": "10.0",
          "bondPage": "5.0",
          "quality100Gsm": "5.0",
          "quality80gsm": "3.0",
          "createdAt": account["createdAt"],
          "updatedAt": updatedAt,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    });
    return null;
  }

  static Future<String?> loginStore({
    required String email,
    required String password,
  }) async {
    final mail = email.trim().toLowerCase();
    final pass = password.trim();
    final stores = await _getStores();
    Map<String, dynamic>? found;
    for (final s in stores) {
      final em = (s["email"] ?? "").toString().toLowerCase();
      final pw = (s["password"] ?? "").toString();
      if (em == mail && pw == pass) {
        found = s;
        break;
      }
    }
    if (found == null && CloudSyncGuard.cloudSyncEnabled) {
      try {
        await _ensureFirebaseSession(
          email: mail,
          password: pass,
          createIfMissing: false,
        );
        final snapshot = await FirebaseFirestore.instance
            .collection("stores")
            .where("email", isEqualTo: mail)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final cloud = Map<String, dynamic>.from(snapshot.docs.first.data());
          final cloudPass = (cloud["password"] ?? "").toString();
          if (cloudPass == pass) {
            found = cloud;
            final updated = List<Map<String, dynamic>>.from(stores)
              ..removeWhere(
                  (s) => (s["email"] ?? "").toString().toLowerCase() == mail)
              ..add(cloud);
            await _setStores(updated);
          }
        }
      } catch (_) {}
    }

    if (found == null) return "Invalid store email or password.";

    await _ensureFirebaseSession(email: mail, password: pass);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveStore, jsonEncode(found));
    return null;
  }

  static Future<String?> resetStorePassword({
    required String email,
    required String newPassword,
  }) async {
    final mail = email.trim().toLowerCase();
    final pass = newPassword.trim();
    if (!mail.contains("@")) return "Enter valid store email.";
    if (pass.length < 6) return "Password must be at least 6 characters.";

    final stores = await _getStores();
    bool updatedLocal = false;
    for (var i = 0; i < stores.length; i++) {
      final em = (stores[i]["email"] ?? "").toString().toLowerCase();
      if (em == mail) {
        stores[i]["password"] = pass;
        updatedLocal = true;
        break;
      }
    }
    if (updatedLocal) {
      await _setStores(stores);
    }

    if (CloudSyncGuard.cloudSyncEnabled) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection("stores")
            .where("email", isEqualTo: mail)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first.reference;
          final cloud = Map<String, dynamic>.from(snap.docs.first.data());
          cloud["password"] = pass;
          cloud["updatedAt"] = DateTime.now().toIso8601String();
          await doc.update({
            "password": pass,
            "updatedAt": cloud["updatedAt"],
          });

          final merged = List<Map<String, dynamic>>.from(stores)
            ..removeWhere(
                (s) => (s["email"] ?? "").toString().toLowerCase() == mail)
            ..add(cloud);
          await _setStores(merged);
          return null;
        }
      } catch (_) {}
    }

    return updatedLocal ? null : "Store account not found for this email.";
  }

  static Future<List<Map<String, dynamic>>> getRegisteredStores() {
    return _getStores();
  }

  static Future<Map<String, dynamic>?> getActiveStore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kActiveStore);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isStoreLoggedIn() async {
    final store = await getActiveStore();
    return store != null;
  }

  static Future<void> logoutStore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveStore);
  }
}
