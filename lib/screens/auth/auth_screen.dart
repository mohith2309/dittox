import "package:flutter/material.dart";

import "./backgroundpaint_screen.dart";
import "./login_screen.dart";
import "./register_screen.dart";

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool showSignIn = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: CustomPaint(
              painter: BackGroundPainter(animation: _animationController.view),
            ),
          ),
          SafeArea(
            child: showSignIn
                ? LoginScreen(
                    callRegisterScreen: () {
                      setState(() => showSignIn = false);
                      _animationController.forward();
                    },
                  )
                : RegisterScreen(
                    callLoginScreen: () {
                      setState(() => showSignIn = true);
                      _animationController.reverse();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
