import 'dart:async';

import 'package:dittox/screens/auth/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/dynamicSizing.dart';
import '../nav_drawers/navBar.dart';

class DittoxSplash extends StatefulWidget {
  final String? accessToken;
  final bool demoMode;

  const DittoxSplash({
    super.key,
    required this.accessToken,
    required this.demoMode,
  });

  @override
  State<DittoxSplash> createState() => _DittoxSplashState();
}

class _DittoxSplashState extends State<DittoxSplash> {
  @override
  void initState() {
    super.initState();
    _navigateToHomeScreen();
  }

  Future<void> _navigateToHomeScreen() async {
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    String token = widget.accessToken ?? '';
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      final freshToken = await firebaseUser.getIdToken(false);
      if (freshToken != null && freshToken.trim().isNotEmpty) {
        token = freshToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('AccessToken', freshToken);
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (token.trim().isNotEmpty || firebaseUser != null) {
            return ButtonNavigationBar(accessToken: token);
          }
          return const AuthScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
            ),
          ),
          child: Image.asset(
            "assets/image/dittox_splash_logo.png",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
