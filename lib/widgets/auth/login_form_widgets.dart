import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';

class AuthTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;
  final bool isObscure;
  final VoidCallback? onVisibilityToggle;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final TextInputType? keyboardType;
  final double screenHeight;
  final double screenWidth;

  const AuthTextFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.isObscure = true,
    this.onVisibilityToggle,
    this.validator,
    this.onSaved,
    this.keyboardType,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = calculateDynamicFontSize(
      totalScreenHeight: screenHeight,
      totalScreenWidth: screenWidth,
      currentFontSize: 40,
    );
    final labelFontSize = calculateDynamicFontSize(
      totalScreenHeight: screenHeight,
      totalScreenWidth: screenWidth,
      currentFontSize: 45,
    );
    final iconSize = calculateDynamicFontSize(
      totalScreenHeight: screenHeight,
      totalScreenWidth: screenWidth,
      currentFontSize: 40,
    );
    final borderWidth = calculateDynamicFontSize(
      totalScreenHeight: screenHeight,
      totalScreenWidth: screenWidth,
      currentFontSize: 2,
    );

    return TextFormField(
      controller: controller,
      obscureText: isPassword && isObscure,
      cursorHeight: fontSize,
      cursorWidth: calculateDynamicFontSize(
        totalScreenHeight: screenHeight,
        totalScreenWidth: screenWidth,
        currentFontSize: 5,
      ),
      cursorColor: ColorPallets.deepBlue,
      style: TextStyle(fontSize: fontSize, color: ColorPallets.deepBlue),
      keyboardType: keyboardType ??
          (isPassword
              ? TextInputType.visiblePassword
              : TextInputType.emailAddress),
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        suffixIcon: controller.text.isEmpty
            ? (isPassword ? const SizedBox() : const SizedBox(width: 0))
            : Padding(
                padding: EdgeInsets.only(
                  top: calculateDynamicFontSize(
                    totalScreenHeight: screenHeight,
                    totalScreenWidth: screenWidth,
                    currentFontSize: 40,
                  ),
                ),
                child: IconButton(
                  // Added tooltip for accessibility and better UX when interacting with the icon button
                  tooltip: isPassword
                      ? (isObscure ? 'Show password' : 'Hide password')
                      : 'Clear text',
                  color: ColorPallets.deepBlue,
                  onPressed: isPassword
                      ? onVisibilityToggle
                      : () => controller.clear(),
                  icon: isPassword
                      ? Icon(
                          isObscure ? Icons.visibility : Icons.visibility_off,
                          size: iconSize)
                      : FaIcon(FontAwesomeIcons.xmark, size: iconSize),
                ),
              ),
        focusColor: ColorPallets.deepBlue,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ColorPallets.deepBlue),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            width: borderWidth,
            color: ColorPallets.deepBlue,
          ),
        ),
        label: Text(
          label,
          style: TextStyle(
            color: ColorPallets.deepBlue,
            fontSize: labelFontSize,
          ),
        ),
        hintText: hint,
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}

class LinkText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double screenHeight;
  final double screenWidth;
  final Color color;

  const LinkText({
    super.key,
    required this.text,
    required this.onTap,
    required this.screenHeight,
    required this.screenWidth,
    this.color = ColorPallets.pinkinshShadedPurple,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: calculateDynamicFontSize(
            totalScreenHeight: screenHeight,
            totalScreenWidth: screenWidth,
            currentFontSize: 35,
          ),
        ),
      ),
    );
  }
}

class DemoModeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final double screenHeight;
  final double screenWidth;

  const DemoModeButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: calculateDynamicFontSize(
          totalScreenHeight: screenHeight,
          totalScreenWidth: screenWidth,
          currentFontSize: 24,
        ),
      ),
      child: Column(
        children: [
          TextButton(
            onPressed: isLoading ? null : onPressed,
            child: Text(
              "Continue In Demo Mode",
              style: TextStyle(
                color: ColorPallets.deepBlue,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: screenHeight,
                  totalScreenWidth: screenWidth,
                  currentFontSize: 34,
                ),
              ),
            ),
          ),
          Text(
            "Use this while the server login is unavailable.",
            style: TextStyle(
              color: Colors.black54,
              fontSize: calculateDynamicFontSize(
                totalScreenHeight: screenHeight,
                totalScreenWidth: screenWidth,
                currentFontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FooterLinks extends StatelessWidget {
  final VoidCallback onPrivacyTap;
  final VoidCallback onTermsTap;
  final double screenHeight;
  final double screenWidth;

  const FooterLinks({
    super.key,
    required this.onPrivacyTap,
    required this.onTermsTap,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: calculateDynamicFontSize(
          totalScreenHeight: screenHeight,
          totalScreenWidth: screenWidth,
          currentFontSize: 15,
        ),
        horizontal: calculateDynamicFontSize(
          totalScreenHeight: screenHeight,
          totalScreenWidth: screenWidth,
          currentFontSize: 8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          LinkText(
            text: "Privacy policy",
            onTap: onPrivacyTap,
            screenHeight: screenHeight,
            screenWidth: screenWidth,
          ),
          LinkText(
            text: "Terms & conditions",
            onTap: onTermsTap,
            screenHeight: screenHeight,
            screenWidth: screenWidth,
          ),
        ],
      ),
    );
  }
}
