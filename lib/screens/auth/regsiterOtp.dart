import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../../utils/auth_error_messages.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';
import '../../utils/firebase_phone_auth.dart';
import '../../utils/firestore_user_profile.dart';
import '../../utils/pill_notifications.dart';
import '../../widgets/IconButton.dart';
import 'auth_screen.dart';

/// SMS-OTP step of registration, backed by Firebase Phone Auth.
///
/// Expected route arguments (from RegisterScreen):
///   { email, userName, password, phoneNumber }
///
/// Flow: send an SMS to the phone -> user enters the 6-digit code -> create the
/// email/password account -> link the verified phone to it -> send the email
/// verification + sign out -> back to the login screen.
class RegisterOtp extends StatefulWidget {
  static const routeName = "/registerOtp";
  const RegisterOtp({super.key});

  @override
  State<RegisterOtp> createState() => _RegisterOtpState();
}

class _RegisterOtpState extends State<RegisterOtp> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  String _email = '';
  String _userName = '';
  String _password = '';
  String _phoneE164 = '';

  String? _verificationId;
  int? _resendToken;
  bool _argsReady = false;
  bool _sending = true;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsReady) return;
    _argsReady = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    _email = (map["email"] ?? '').toString().trim();
    _userName = (map["userName"] ?? '').toString().trim();
    _password = (map["password"] ?? '').toString();
    _phoneE164 = FirebasePhoneAuth.toE164((map["phoneNumber"] ?? '').toString());
    _startVerification();
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    if (mounted) setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneE164,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (credential) {
          // Android instant-retrieval / auto-resolution.
          _completeRegistration(credential);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _sending = false);
          PillNotifications.show(
            context,
            message: friendlyAuthError(e),
            type: PillType.error,
          );
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _sending = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      PillNotifications.show(
        context,
        message: "Couldn't send the code. Check the number and try again.",
        type: PillType.error,
      );
    }
  }

  void _submit() {
    if (_busy) return;
    final code = pinController.text.trim();
    if (_verificationId == null) {
      PillNotifications.show(
        context,
        message: "Still sending the code. Please wait a moment.",
        type: PillType.warning,
      );
      return;
    }
    if (code.length != 6) {
      PillNotifications.show(
        context,
        message: "Enter the 6-digit code sent to your phone.",
        type: PillType.error,
      );
      return;
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    );
    _completeRegistration(credential);
  }

  Future<void> _completeRegistration(
      PhoneAuthCredential phoneCredential) async {
    if (_busy) return;
    _busy = true;
    if (mounted) setState(() {});
    focusNode.unfocus();

    try {
      final account =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      final user = account.user;
      if (user == null) throw FirebaseAuthException(code: 'unknown');

      await user.updateDisplayName(_userName);

      // Linking validates the SMS code and attaches the verified phone.
      try {
        await user.linkWithCredential(phoneCredential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'invalid-verification-code' ||
            e.code == 'session-expired' ||
            e.code == 'invalid-verification-id') {
          // Bad/expired code: roll back the just-created account so the user
          // can retry cleanly without an "email already in use" error.
          await user.delete();
          rethrow;
        }
        // Phone already linked elsewhere etc.: keep the account; the verified
        // number is still saved to the profile below.
      }

      await FirestoreUserProfile.save(
        uid: user.uid,
        name: _userName,
        email: _email,
        phone: _phoneE164,
      );
      await user.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      PillNotifications.show(
        context,
        message: "Account created. Verify your email, then sign in.",
        type: PillType.success,
        duration: const Duration(seconds: 4),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    } on FirebaseAuthException catch (e) {
      pinController.clear();
      if (!mounted) return;
      PillNotifications.show(
        context,
        message: friendlyAuthError(e),
        type: PillType.error,
      );
    } catch (_) {
      if (!mounted) return;
      PillNotifications.show(
        context,
        message: "Couldn't complete sign up right now. Please try again.",
        type: PillType.error,
      );
    } finally {
      _busy = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;

    final defaultPinTheme = PinTheme(
      width: calculateDynamicFontSize(
        totalScreenHeight: totalScreenHeight,
        totalScreenWidth: totalScreenWidth,
        currentFontSize: 90,
      ),
      height: calculateDynamicFontSize(
        totalScreenHeight: totalScreenHeight,
        totalScreenWidth: totalScreenWidth,
        currentFontSize: 100,
      ),
      textStyle: TextStyle(
        fontSize: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 50,
        ),
        color: ColorPallets.deepBlue,
      ),
      decoration: BoxDecoration(
        color: ColorPallets.lightBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 40,
          ),
        ),
        border:
            Border.all(color: ColorPallets.lightBlue.withValues(alpha: 0.2)),
      ),
    );

    final cursor = Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 40,
        ),
        height: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 3,
        ),
        margin: EdgeInsets.only(
          bottom: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 12,
          ),
        ),
        decoration: BoxDecoration(
          color: ColorPallets.deepBlue,
          borderRadius: BorderRadius.circular(
            calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 18,
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 200,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                ),
                horizontal: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 50,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomIconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: FontAwesomeIcons.chevronLeft,
                    iconColor: ColorPallets.white,
                    tooltip: "Back",
                    semanticLabel: "Go back",
                    backGroundColor: ColorPallets.deepBlue,
                    size: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 80,
                    ).toInt(),
                    iconSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 40,
                    ).toInt(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Image.asset("assets/image/otp.png", fit: BoxFit.cover),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 60,
                ),
                horizontal: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 60,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      _sending
                          ? "Sending a verification code to\n${FirebasePhoneAuth.maskForDisplay(_phoneE164)}"
                          : "Enter the verification code sent to\n${FirebasePhoneAuth.maskForDisplay(_phoneE164)}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 38,
                        ),
                        color: const Color.fromARGB(255, 6, 1, 8),
                      ),
                    ),
                    SizedBox(
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 60,
                      ),
                    ),
                    Pinput(
                      length: 6,
                      controller: pinController,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      defaultPinTheme: defaultPinTheme,
                      separatorBuilder: (index) => SizedBox(
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 25,
                        ),
                      ),
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: BoxDecoration(
                          color: ColorPallets.white,
                          borderRadius: BorderRadius.circular(
                            calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 8,
                            ),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.06),
                              offset: Offset(0, 3),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      errorPinTheme: defaultPinTheme.copyBorderWith(
                        border: Border.all(color: Colors.redAccent),
                      ),
                      onCompleted: (_) => _submit(),
                      showCursor: true,
                      cursor: cursor,
                    ),
                    SizedBox(
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                      ),
                    ),
                    TextButton(
                      onPressed: (_sending || _busy) ? null : _startVerification,
                      child: const Text("Resend code"),
                    ),
                    SizedBox(
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                      ),
                    ),
                    InkWell(
                      onTap: (_sending || _busy) ? null : _submit,
                      child: Container(
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 110,
                        ),
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 300,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 60,
                            ),
                          ),
                          color: ColorPallets.deepBlue.withValues(alpha: 0.9),
                        ),
                        child: (_busy || _sending)
                            ? const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: ColorPallets.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : Text(
                                "Verify & create account",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ColorPallets.white,
                                  fontSize: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 40,
                                  ),
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
