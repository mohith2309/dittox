import 'dart:ui';

import "package:flutter/material.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import "../../utils/auth_error_messages.dart";
import "../../utils/color_pallets.dart";
import '../../utils/dynamicSizing.dart';
import "../../utils/firestore_user_profile.dart";
import "../../widgets/auth/sing_in_up_bar.dart";

class RegisterScreen extends StatefulWidget {
  final VoidCallback callLoginScreen;
  const RegisterScreen({
    super.key,
    required this.callLoginScreen,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKeyRegister = GlobalKey<FormState>();
  bool _isLoading = false;

  final emailController = TextEditingController();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final phonenumberController = TextEditingController();

  bool isObsecureText = true;

  InputDecoration _glassInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF234B52)),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8EB2B8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorPallets.deepBlue, width: 2),
      ),
    );
  }

  @override
  void initState() {
    emailController.addListener(() => setState(() {}));
    userNameController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    // addressController.addListener(() => setState(() {}));
    phonenumberController.addListener(() => setState(() {}));
    // dobcontroller.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    addressController.dispose();
    phonenumberController.dispose();
    // dobcontroller.dispose();
    super.dispose();
  }

  Future<void> registerUser(
    BuildContext ctx,
    double totalScreenHeight,
    double totalScreenWidth,
  ) async {
    var msg = "Invalid Credentials !!!";
    final isValid = formKeyRegister.currentState!.validate();

    if (isValid) {
      formKeyRegister.currentState!.save();
      Map<String, String> userDetails = {
        "email": emailController.text,
        "password": passwordController.text,
        "userName": userNameController.text,
        "phoneNumber": phonenumberController.text,
      };

      setState(() => _isLoading = true);
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: userDetails["email"].toString().trim(),
          password: userDetails["password"].toString().trim(),
        );
        final newUser = cred.user;
        await newUser?.updateDisplayName(userDetails["userName"]);
        // Persist the profile (incl. phone, which email accounts don't carry)
        // while still authenticated, before signing out.
        if (newUser != null) {
          await FirestoreUserProfile.save(
            uid: newUser.uid,
            name: userDetails["userName"] ?? "",
            email: userDetails["email"] ?? "",
            phone: userDetails["phoneNumber"] ?? "",
          );
        }
        await newUser?.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        emailController.clear();
        passwordController.clear();
        userNameController.clear();
        phonenumberController.clear();

        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: ColorPallets.deepBlue,
            content: Text(
              "Account created. Verify email and login.",
              style: TextStyle(color: ColorPallets.white),
            ),
          ),
        );
        widget.callLoginScreen();
      } on FirebaseAuthException catch (e) {
        msg = friendlyAuthError(e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ColorPallets.deepBlue,
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                        ),
                        fontStyle: FontStyle.normal,
                        color: ColorPallets.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ColorPallets.deepBlue,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              Text(
                msg,
                style: TextStyle(
                  // fontSize: 18,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ),
                  fontStyle: FontStyle.normal,
                  color: ColorPallets.white,
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;

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
                          key: formKeyRegister,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Create\nAccount",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 38,
                                  color: const Color(0xFF12333A),
                                  fontWeight: FontWeight.w600,
                                  fontFamily:
                                      GoogleFonts.audiowide().fontFamily,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style:
                                    const TextStyle(color: Color(0xFF102A2E)),
                                decoration: _glassInputDecoration("E-mail"),
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      !value.contains("@")) {
                                    return "Invalid EmailId";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: userNameController,
                                style:
                                    const TextStyle(color: Color(0xFF102A2E)),
                                decoration: _glassInputDecoration("UserName"),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "UserName is required";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: passwordController,
                                obscureText: isObsecureText,
                                obscuringCharacter: "*",
                                style:
                                    const TextStyle(color: Color(0xFF102A2E)),
                                decoration:
                                    _glassInputDecoration("Password").copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() =>
                                          isObsecureText = !isObsecureText);
                                    },
                                    // Accessibility: Tooltip provides semantic labels for icon-only buttons
                                    tooltip: isObsecureText ? "Show password" : "Hide password",
                                    icon: Icon(
                                      isObsecureText
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFF234B52),
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return "password min of 6 char";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: phonenumberController,
                                keyboardType: TextInputType.phone,
                                style:
                                    const TextStyle(color: Color(0xFF102A2E)),
                                decoration:
                                    _glassInputDecoration("Mobile number"),
                                validator: (value) {
                                  if (value == null || value.length != 10) {
                                    return "Invalid PhoneNumber";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              SignUpBar(
                                isLoading: _isLoading,
                                label: "Register",
                                onPressed: () => registerUser(
                                  context,
                                  totalScreenHeight,
                                  totalScreenWidth,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "I'm a member !! ",
                                    style: TextStyle(color: Color(0xFF12333A)),
                                  ),
                                  InkWell(
                                    onTap: widget.callLoginScreen,
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                          color: ColorPallets
                                              .pinkinshShadedPurple),
                                    ),
                                  ),
                                ],
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
