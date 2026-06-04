import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/auth_error_messages.dart';
import '../../utils/color_pallets.dart';
import '../../utils/pill_notifications.dart';

import '../../utils/dynamicSizing.dart';
import "../../widgets/IconButton.dart";

class ForgetPasswordScreen extends StatefulWidget {
  static const routeName = "/forgetPassword";
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    emailController.addListener(() => setState(() {}));
    super.initState();
  }

  Future<void> sendResetEmail(
    double totalScreenHeight,
    double totalScreenWidth,
  ) async {
    if (_isSending) return;
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showAuthSnackBar(
        "Enter the email you registered with.",
        totalScreenHeight,
        totalScreenWidth,
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      PillNotifications.show(
        context,
        message: "Password reset link sent to $email. Check your inbox.",
        type: PillType.success,
        duration: const Duration(seconds: 4),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an email is registered (account enumeration).
      if (e.code == 'user-not-found') {
        if (!mounted) return;
        PillNotifications.show(
          context,
          message:
              "If an account exists for $email, a reset link is on its way.",
          type: PillType.success,
          duration: const Duration(seconds: 4),
        );
        Navigator.of(context).pop();
        return;
      }
      _showAuthSnackBar(
        friendlyAuthError(e),
        totalScreenHeight,
        totalScreenWidth,
      );
    } catch (_) {
      _showAuthSnackBar(
        "Couldn't send the reset link right now. Please try again.",
        totalScreenHeight,
        totalScreenWidth,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showAuthSnackBar(
    String message,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    if (!mounted) return;
    PillNotifications.show(
      context,
      message: message,
      type: PillType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            // height: 90,
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 200,
              // heightSpecific: true,
            ),
            child: Padding(
              // padding: const EdgeInsets.symmetric(
              //   vertical: 10,
              //   horizontal: 20,
              // ),
              padding: EdgeInsets.symmetric(
                vertical: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
                horizontal: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 50,
                  // heightSpecific: false,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomIconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).clearSnackBars();
                    },
                    icon: FontAwesomeIcons.chevronLeft,
                    iconColor: ColorPallets.white,
                    backGroundColor: ColorPallets.deepBlue,
                    // size: 40,
                    size: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 80,
                      // heightSpecific: true,
                    ).toInt(),
                    // iconSize: 16,
                    iconSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 40,
                      // heightSpecific: true,
                    ).toInt(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Image.asset(
              "assets/image/forgotPassword.png",
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              // padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              padding: EdgeInsets.symmetric(
                vertical: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 30,
                  // heightSpecific: true,
                ),
                horizontal: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 50,
                  // heightSpecific: false,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      "Enter your account email\nWe'll email you a reset link",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        // fontSize: 20,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 38,
                          // heightSpecific: true,
                        ),
                        color: const Color.fromARGB(255, 6, 1, 8),
                      ),
                    ),
                    SizedBox(
                      // height: 10,
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 60,
                        // heightSpecific: true,
                      ),
                    ),
                    TextField(
                      controller: emailController,
                      // cursorHeight: 22,
                      cursorHeight: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 50,
                        // heightSpecific: true,
                      ),
                      // cursorWidth: 2,
                      cursorWidth: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 5,
                        // heightSpecific: true,
                      ),
                      cursorColor: ColorPallets.deepBlue,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        // fontSize: 18,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                          // heightSpecific: true,
                        ),
                        color: ColorPallets.deepBlue,
                      ),
                      decoration: InputDecoration(
                        label: Text(
                          "Email",
                          style: TextStyle(
                            color: ColorPallets.deepBlue,
                            fontSize: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 45,
                              // heightSpecific: false,
                            ),
                          ),
                        ),
                        // border: const OutlineInputBorder(
                        //   borderSide:
                        //         BorderSide(color: ColorPallets.deepBlue)
                        // ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: ColorPallets.deepBlue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            // width: 2,
                            width: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 3,
                              // heightSpecific: false,
                            ),
                            color: ColorPallets.deepBlue,
                          ),
                        ),
                        focusColor: ColorPallets.deepBlue,
                        hintText: "you@example.com",
                        suffixIcon: emailController.text.isEmpty
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: IconButton(
                                  onPressed: () {
                                    emailController.clear();
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
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(
                      // height: 40,
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 100,
                        // heightSpecific: true,
                      ),
                    ),
                    InkWell(
                      onTap: _isSending
                          ? null
                          : () => sendResetEmail(
                                totalScreenHeight,
                                totalScreenWidth,
                              ),
                      child: Container(
                        // height: 50,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 100,
                          // heightSpecific: true,
                        ),
                        // width: 180,
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 300,
                          // heightSpecific: true,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          // borderRadius: BorderRadius.circular(20),
                          borderRadius: BorderRadius.circular(
                            calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 45,
                              // heightSpecific: true,
                            ),
                          ),
                          color: ColorPallets.deepBlue.withValues(alpha: 0.9),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: ColorPallets.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                "Send reset link",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ColorPallets.white,
                                  fontSize: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 40,
                                  ),
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
