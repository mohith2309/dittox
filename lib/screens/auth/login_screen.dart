import 'dart:ui';

import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:geolocator/geolocator.dart";
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import "package:provider/provider.dart";
import 'package:shared_preferences/shared_preferences.dart';

import "../../helpers/sqlLite.dart";
import "../../helpers/user_location.dart";
import "../../providers/current_user.dart";
import "../../utils/auth_error_messages.dart";
import "../../utils/color_pallets.dart";
import "../../utils/dynamicSizing.dart";
import "../../utils/firestore_user_profile.dart";
import "../../utils/pill_notifications.dart";
import "../nav_drawers/navBar.dart";
import "./forget_password_screen.dart";
import "../../widgets/auth/sing_in_up_bar.dart";
import "../../widgets/auth/login_form_widgets.dart";
import "../../model/user.dart";
import "privacy_policy.dart";
import "termsandcondictions.dart";

class LoginScreen extends StatefulWidget {
  final VoidCallback callRegisterScreen;
  const LoginScreen({super.key, required this.callRegisterScreen});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final focusNode = FocusNode();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isObsureText = true;

  final Map<String, String> _userDetails = {"email": "", "password": ""};

  @override
  void initState() {
    emailController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> submitSinginform(BuildContext ctx, CurrentUser currentUser,
      double totalScreenHeight, double totalScreenWidth) async {
    focusNode.unfocus();
    var isValid = formKey.currentState!.validate();
    if (isValid) {
      formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        // _tryFirebaseLogin surfaces its own specific error message on failure;
        // don't show a second generic one here or it clobbers the real reason.
        await _tryFirebaseLogin(
          currentUser,
          totalScreenHeight,
          totalScreenWidth,
        );
      } catch (_) {
        _showAuthSnackBar(
          "Unable to sign in right now. Please try again.",
          totalScreenHeight,
          totalScreenWidth,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _tryFirebaseLogin(
    CurrentUser currentUser,
    double totalScreenHeight,
    double totalScreenWidth,
  ) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _userDetails["email"].toString().trim(),
        password: _userDetails["password"].toString().trim(),
      );
      final firebaseUser = cred.user;
      if (firebaseUser == null) {
        _showAuthSnackBar(
          "Unable to sign in right now. Please try again.",
          totalScreenHeight,
          totalScreenWidth,
        );
        return false;
      }

      final idToken = await firebaseUser.getIdToken(true);
      // Email/password accounts don't carry the phone number or always a
      // display name — pull them from the profile written at registration.
      final profile = await FirestoreUserProfile.load(uid: firebaseUser.uid);
      final profileName = profile?["name"]?.toString().trim() ?? "";
      final profilePhone = profile?["phone"]?.toString().trim() ?? "";

      final resolvedName = firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!
          : (profileName.isNotEmpty
              ? profileName
              : _userDetails["email"].toString().split("@").first);
      final resolvedPhone = firebaseUser.phoneNumber?.trim().isNotEmpty == true
          ? firebaseUser.phoneNumber!
          : profilePhone;

      // Soft email-verification notice (does not block sign-in).
      if (!firebaseUser.emailVerified) {
        await _promptVerifyEmail(firebaseUser);
      }

      await _completeLogin(
        currentUser: currentUser,
        userId: firebaseUser.uid,
        userName: resolvedName,
        userEmail: firebaseUser.email ?? _userDetails["email"].toString(),
        userPhone: resolvedPhone,
        accessToken: idToken ?? "",
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _showAuthSnackBar(
        friendlyAuthError(e),
        totalScreenHeight,
        totalScreenWidth,
      );
    }
    return false;
  }

  /// Shown when a signed-in account hasn't verified its email yet. Offers a
  /// resend but lets the user continue — registration already promised a link.
  Future<void> _promptVerifyEmail(User user) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Verify your email"),
        content: Text(
          "We sent a verification link to ${user.email ?? 'your email'}. "
          "Verifying secures your account — you can continue for now.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                await user.sendEmailVerification();
                if (!mounted) return;
                PillNotifications.show(
                  context,
                  message: "Verification link sent. Check your inbox.",
                  type: PillType.success,
                );
              } catch (_) {
                if (!mounted) return;
                PillNotifications.show(
                  context,
                  message: "Couldn't resend the link right now.",
                  type: PillType.error,
                );
              }
            },
            child: const Text("Resend link"),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  Future<void> _completeLogin({
    required CurrentUser currentUser,
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("UseDemoMode");
    await prefs.setString("AccessToken", accessToken);
    await SQLHelpers.checkUserPresent(userId);

    Position? userCurrentPosition;
    Map<String, dynamic>? userPlaceMark;
    try {
      userCurrentPosition = await UserLocation.getUserLatLong();
      userPlaceMark = await UserLocation.getUserPlaceMarks(
        userCurrentPosition.latitude,
        userCurrentPosition.longitude,
      );
    } catch (_) {
      userCurrentPosition = null;
      userPlaceMark = null;
    }

    var user = Users(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPlaceName: userPlaceMark?["locality"]?.toString() ?? "Bangalore",
      latitude: userCurrentPosition?.latitude ?? 12.972442,
      longitude: userCurrentPosition?.longitude ?? 77.580643,
      userPhoneNumber: userPhone,
      userContryName: userPlaceMark?["country"]?.toString() ?? "India",
      userAccessToken: accessToken,
    );
    currentUser.setCurrentUser(user);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (ctx) => ButtonNavigationBar(accessToken: accessToken)),
      (route) => false,
    );
  }

  Future<void> _completeOAuthLogin(
    CurrentUser currentUser,
    User user,
  ) async {
    final idToken = await user.getIdToken(true);
    await _completeLogin(
      currentUser: currentUser,
      userId: user.uid,
      userName: (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!
          : (user.email?.split("@").first ?? "User"),
      userEmail: user.email ?? "",
      userPhone: user.phoneNumber ?? "",
      accessToken: idToken ?? "",
    );
  }

  Future<void> _signInWithGoogle(
    CurrentUser currentUser,
    double totalScreenHeight,
    double totalScreenWidth,
  ) async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        await _completeOAuthLogin(currentUser, user);
      }
    } on FirebaseAuthException catch (e) {
      _showAuthSnackBar(
        friendlyAuthError(e),
        totalScreenHeight,
        totalScreenWidth,
      );
    } catch (_) {
      _showAuthSnackBar(
        "Google sign-in failed.",
        totalScreenHeight,
        totalScreenWidth,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAuthSnackBar(
      String message, double totalScreenHeight, double totalScreenWidth) {
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
    final currUser = Provider.of<CurrentUser>(context, listen: false);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.login_rounded,
                                    color: ColorPallets.deepBlue,
                                    size: 34,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Welcome\nBack",
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 38,
                                      color: const Color(0xFF12333A),
                                      fontFamily:
                                          GoogleFonts.audiowide().fontFamily,
                                      height: 1.05,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style:
                                    const TextStyle(color: Color(0xFF102A2E)),
                                decoration: InputDecoration(
                                  labelText: "E-mail",
                                  labelStyle:
                                      const TextStyle(color: Color(0xFF234B52)),
                                  hintText: "xxxxxxx@xxxx.xxx",
                                  hintStyle: TextStyle(
                                      color:
                                          Colors.black.withValues(alpha: 0.45)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF8EB2B8)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: ColorPallets.pinkinshShadedPurple,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (email) {
                                  if (email == null ||
                                      email.isEmpty ||
                                      !email.contains('@')) {
                                    return "Invalid EmailId";
                                  }
                                  return null;
                                },
                                onSaved: (email) =>
                                    _userDetails["email"] = email ?? "",
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: passwordController,
                                obscureText: isObsureText,
                                obscuringCharacter: "*",
                                style:
                                    const TextStyle(color: Color(0xFF102A2E)),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle:
                                      const TextStyle(color: Color(0xFF234B52)),
                                  hintText: "••••••",
                                  hintStyle: TextStyle(
                                      color:
                                          Colors.black.withValues(alpha: 0.45)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF8EB2B8)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: ColorPallets.pinkinshShadedPurple,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                        () => isObsureText = !isObsureText),
                                    icon: Icon(
                                      isObsureText
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFF234B52),
                                    ),
                                  ),
                                ),
                                validator: (password) {
                                  if (password == null ||
                                      password.isEmpty ||
                                      password.length < 6) {
                                    return "password min of 6 char";
                                  }
                                  return null;
                                },
                                onSaved: (password) =>
                                    _userDetails["password"] = password ?? "",
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 50,
                                  ),
                                  horizontal: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 15,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    LinkText(
                                      text: "Forget Password ?",
                                      onTap: () => Navigator.of(context)
                                          .pushNamed(
                                              ForgetPasswordScreen.routeName),
                                      screenHeight: totalScreenHeight,
                                      screenWidth: totalScreenWidth,
                                    ),
                                  ],
                                ),
                              ),
                              SignInBar(
                                isLoading: _isLoading,
                                label: "Sign In",
                                onPressed: () => submitSinginform(
                                    context,
                                    currUser,
                                    totalScreenHeight,
                                    totalScreenWidth),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 28,
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.link_rounded,
                                        color: ColorPallets.white,
                                        size: calculateDynamicFontSize(
                                          totalScreenHeight: totalScreenHeight,
                                          totalScreenWidth: totalScreenWidth,
                                          currentFontSize: 28,
                                        ),
                                      ),
                                      SizedBox(
                                        width: calculateDynamicFontSize(
                                          totalScreenHeight: totalScreenHeight,
                                          totalScreenWidth: totalScreenWidth,
                                          currentFontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        "or continue with",
                                        style: TextStyle(
                                          color: ColorPallets.white,
                                          fontSize: calculateDynamicFontSize(
                                            totalScreenHeight:
                                                totalScreenHeight,
                                            totalScreenWidth: totalScreenWidth,
                                            currentFontSize: 32,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _signInWithGoogle(
                                            currUser,
                                            totalScreenHeight,
                                            totalScreenWidth,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                  ),
                                  icon: const Icon(Icons.g_mobiledata),
                                  label: const Text("Google"),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 40,
                                  ),
                                  horizontal: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 16,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Create an account",
                                      style: TextStyle(
                                        fontSize: calculateDynamicFontSize(
                                          totalScreenHeight: totalScreenHeight,
                                          totalScreenWidth: totalScreenWidth,
                                          currentFontSize: 40,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    LinkText(
                                      text: "Register",
                                      onTap: widget.callRegisterScreen,
                                      screenHeight: totalScreenHeight,
                                      screenWidth: totalScreenWidth,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 30,
                                ),
                              ),
                              FooterLinks(
                                onPrivacyTap: () => Navigator.of(context)
                                    .pushNamed(PrivacyPolicy.routeName),
                                onTermsTap: () => Navigator.of(context)
                                    .pushNamed(TermsAndCond.routeName),
                                screenHeight: totalScreenHeight,
                                screenWidth: totalScreenWidth,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
