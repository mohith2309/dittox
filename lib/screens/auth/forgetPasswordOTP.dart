import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;

import 'auth_screen.dart';
import '../../utils/api_endpoints.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';
import '../../utils/pill_notifications.dart';
import '../../widgets/IconButton.dart';

class PasswordOTP extends StatefulWidget {
  static const routeName = "/forgetPasswordOtp";
  const PasswordOTP({super.key});

  @override
  State<PasswordOTP> createState() => _PasswordOTPState();
}

class _PasswordOTPState extends State<PasswordOTP> {
  final pinController = TextEditingController();
  final newPasswordController = TextEditingController();
  final focusNode = FocusNode();
  bool _isLoading = false;
  bool isObsecureText = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    pinController.dispose();
    newPasswordController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _resetPassword(
    String newPassword,
    String phoneNumber,
    String otp,
    double totalScreenHeight,
    double totalScreenWidth,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, String> requestBody = {
        "password": newPassword,
        "otp": otp,
        "mobile": phoneNumber,
      };

      var responce = await http
          .post(
            Uri.parse(ApiEndPoiunts.resetPasswordConfirm),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(requestBody),
          )
          .timeout(ApiEndPoiunts.requestTimeout);
      var jsonResponce = jsonDecode(responce.body);
      var responseCode = jsonResponce["responseCode"].toString();
      if (responseCode == "OK") {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const AuthScreen()),
          (route) => false,
        );
      } else {
        _showAuthSnackBar(
          jsonResponce["message"]?.toString() ??
              "Unable to reset the password.",
          totalScreenHeight,
          totalScreenWidth,
        );
      }
    } on TimeoutException {
      _showAuthSnackBar(
        ApiEndPoiunts.backendUnavailableMessage,
        totalScreenHeight,
        totalScreenWidth,
      );
    } catch (e) {
      _showAuthSnackBar(
        "Unable to reset the password right now.",
        totalScreenHeight,
        totalScreenWidth,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    final defaultPinTheme = PinTheme(
      // width: 42,
      width: calculateDynamicFontSize(
        totalScreenHeight: totalScreenHeight,
        totalScreenWidth: totalScreenWidth,
        currentFontSize: 90,
        // heightSpecific: false,
      ),

      // height: 50,
      height: calculateDynamicFontSize(
        totalScreenHeight: totalScreenHeight,
        totalScreenWidth: totalScreenWidth,
        currentFontSize: 100,
        // heightSpecific: true,
      ),
      // textStyle: GoogleFonts.poppins(
      //   fontSize: 20,
      //   color: const Color.fromRGBO(70, 69, 66, 1),
      // ),
      textStyle: TextStyle(
        // fontSize: 20,
        fontSize: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 50,
          // heightSpecific: true,
        ),
        color: ColorPallets.deepBlue,
      ),
      // decoration: BoxDecoration(
      //   color: const Color.fromRGBO(232, 235, 241, 0.37),
      //   borderRadius: BorderRadius.circular(24),
      // ),
      decoration: BoxDecoration(
        // color: const Color.fromARGB(255, 162, 235, 238).withValues(alpha: 0.1),
        color: ColorPallets.lightBlue.withValues(alpha: 0.1),
        // borderRadius: BorderRadius.circular(24),
        borderRadius: BorderRadius.circular(
          calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 40,
            // heightSpecific: true,
          ),
        ),
        border:
            Border.all(color: ColorPallets.lightBlue.withValues(alpha: 0.2)),
      ),
    );

    final cursor = Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        // width: 21,
        width: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 40,
          // heightSpecific: false,
        ),
        // height: 1,
        height: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 3,
          // heightSpecific: true,
        ),
        margin: EdgeInsets.only(
          // bottom: 12,
          bottom: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 12,
            // heightSpecific: true,
          ),
        ),
        decoration: BoxDecoration(
          color: ColorPallets.deepBlue,
          // borderRadius: BorderRadius.circular(8),
          borderRadius: BorderRadius.circular(
            calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 18,
              // heightSpecific: true,
            ),
          ),
        ),
      ),
    );

    Map<String, String> myMap =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>;
    String otp = myMap["otp"].toString();
    String phoneNumber = myMap["phoneNumber"].toString();

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
              padding: EdgeInsets.symmetric(
                // vertical: 10,
                vertical: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
                // horizontal: 20,
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
                    tooltip: 'Go back',
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
            flex: 2,
            child: Image.asset("assets/image/otp.png", fit: BoxFit.cover),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              // padding: const EdgeInsets.symmetric(
              //   vertical: 20,
              //   horizontal: 30,
              // ),
              padding: EdgeInsets.symmetric(
                // vertical: 10,
                vertical: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 60,
                  // heightSpecific: true,
                ),
                // horizontal: 20,
                horizontal: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 60,
                  // heightSpecific: false,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      "Enter the Verification code \nThat has been send to +91-$phoneNumber",
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
                      // height: 30,
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 60,
                        // heightSpecific: true,
                      ),
                    ),
                    Pinput(
                      length: 6,
                      controller: pinController,
                      focusNode: focusNode,
                      validator: (pin) {
                        return pin == otp ? null : "OTP is incorrect";
                      },
                      defaultPinTheme: defaultPinTheme,
                      separatorBuilder: (index) => SizedBox(
                        // width: 5,
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 25,
                          // heightSpecific: false,
                        ),
                      ),
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: BoxDecoration(
                          color: ColorPallets.white,
                          borderRadius: BorderRadius.circular(
                            // 8,
                            calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 8,
                              // heightSpecific: true,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(
                                0,
                                0,
                                0,
                                0.05999999865889549,
                              ),
                              offset: Offset(
                                0,
                                // 3,
                                calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 3,
                                  // heightSpecific: true,
                                ),
                              ),
                              // blurRadius: 16,
                              blurRadius: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 16,
                                // heightSpecific: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // onClipboardFound: (value) {
                      //   debugPrint('onClipboardFound: $value');
                      //   controller.setText(value);
                      // },
                      errorPinTheme: defaultPinTheme.copyBorderWith(
                        border: Border.all(color: Colors.redAccent),
                      ),
                      onCompleted: (value) {
                        // _createNewUser(userName, email, phoneNumber, password,
                        //     otp, currUser);
                      },
                      showCursor: true,
                      cursor: cursor,
                      onSubmitted: (value) {
                        // _createNewUser(userName, email, phoneNumber, password,
                        //     otp, currUser);
                      },
                    ),
                    SizedBox(
                      // height: 60,
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 110,
                        // heightSpecific: true,
                      ),
                    ),
                    TextField(
                      controller: newPasswordController,
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
                        // heightSpecific: false,
                      ),
                      cursorColor: ColorPallets.deepBlue,
                      keyboardType: TextInputType.text,
                      obscureText: isObsecureText,
                      textInputAction: TextInputAction.done,
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
                        suffixIcon: newPasswordController.text.isEmpty
                            ? const SizedBox()
                            : Padding(
                                padding: EdgeInsets.only(
                                  // top: 10,
                                  top: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 40,
                                    // heightSpecific: true,
                                  ),
                                ),
                                child: IconButton(
                                  color: ColorPallets.white,
                                  icon: isObsecureText
                                      ? Icon(
                                          Icons.visibility,
                                          // size: 22,
                                          size: calculateDynamicFontSize(
                                            totalScreenHeight:
                                                totalScreenHeight,
                                            totalScreenWidth: totalScreenWidth,
                                            currentFontSize: 40,
                                            // heightSpecific: true,
                                          ),
                                        )
                                      : Icon(
                                          Icons.visibility_off,
                                          // size: 22,
                                          size: calculateDynamicFontSize(
                                            totalScreenHeight:
                                                totalScreenHeight,
                                            totalScreenWidth: totalScreenWidth,
                                            currentFontSize: 40,
                                            // heightSpecific: true,
                                          ),
                                        ),
                                  onPressed: () {
                                    setState(() {
                                      isObsecureText = !isObsecureText;
                                    });
                                  },
                                ),
                              ),
                        label: Text(
                          "New - Password",
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
                              currentFontSize: 2,
                              // heightSpecific: false,
                            ),
                            color: ColorPallets.deepBlue,
                          ),
                        ),
                        focusColor: ColorPallets.deepBlue,
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
                      onTap: () {
                        _resetPassword(
                          newPasswordController.text.toString().trim(),
                          phoneNumber,
                          otp,
                          totalScreenHeight,
                          totalScreenWidth,
                        );
                        // _createNewUser(userName, email, phoneNumber, password,
                        //     otp, currUser);
                      },
                      child: Container(
                        // height: 50,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 130,
                          // heightSpecific: true,
                        ),
                        // width: 180,
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 350,
                          // heightSpecific: false,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            // 20,
                            calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 60,
                              // heightSpecific: true,
                            ),
                          ),
                          color: ColorPallets.deepBlue.withValues(alpha: 0.9),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: ColorPallets.white,
                                ),
                              )
                            : Text(
                                "Reset Password",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ColorPallets.white,
                                  // fontSize: 24,
                                  fontSize: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 40,
                                    // heightSpecific: true,
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

// TextField(
//                       controller: emailController,
//                       cursorHeight: 22,
//                       cursorWidth: 2,
//                       cursorColor: ColorPallets.deepBlue,
//                       style: const TextStyle(
//                           fontSize: 18, color: ColorPallets.deepBlue),
//                       decoration: InputDecoration(
//                           label: const Text(
//                             "email",
//                             style: TextStyle(color: ColorPallets.deepBlue),
//                           ),
//                           // border: const OutlineInputBorder(
//                           //   borderSide:
//                           //         BorderSide(color: ColorPallets.deepBlue)
//                           // ),
//                           focusedBorder: const OutlineInputBorder(
//                               borderSide:
//                                   BorderSide(color: ColorPallets.deepBlue)),
//                           enabledBorder: const OutlineInputBorder(
//                             borderSide: BorderSide(
//                               width: 2,
//                               color: ColorPallets.deepBlue,
//                             ),
//                           ),
//                           focusColor: ColorPallets.deepBlue,
//                           hintText: "vachira@xerox.com",
//                           suffixIcon: emailController.text.isEmpty
//                               ? const SizedBox()
//                               : Padding(
//                                   padding: const EdgeInsets.only(top: 0),
//                                   child: IconButton(
//                                       onPressed: () {
//                                         emailController.clear();
//                                       },
//                                       icon: const Icon(
//                                         FontAwesomeIcons.xmark,
//                                         size: 18,
//                                       )),
//                                 )),
//                     ),
