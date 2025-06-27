// widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

Widget buildGlassmorphicCard({
  required Widget child,
  EdgeInsets? margin,
}) {
  return Container(
    margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: ColorConstants.MAINCOLOR.withOpacity(0.1),
          blurRadius: 30,
          offset: const Offset(0, 15),
          spreadRadius: -5,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

Widget buildModernTextField({
  required String label,
  required TextEditingController controller,
  bool isPassword = false,
  IconData? prefixIcon,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ColorConstants.TEXT_COLOR,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: ColorConstants.MAINCOLOR.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: ColorConstants.MAINCOLOR.withOpacity(0.7))
            : null,
        filled: true,
        fillColor: ColorConstants.MAINCOLOR.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ColorConstants.MAINCOLOR.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ColorConstants.MAINCOLOR,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    ),
  );
}

Widget buildGradientButton({
  required String text,
  required VoidCallback onPressed,
  bool isPrimary = true,
  bool isLoading = false,
}) {
  return Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      gradient: isPrimary
          ? LinearGradient(
              colors: [
                ColorConstants.MAINCOLOR,
                ColorConstants.SECONDARY_COLOR,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isPrimary
          ? [
              BoxShadow(
                color: ColorConstants.MAINCOLOR.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  text,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : ColorConstants.MAINCOLOR,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    ),
  );
}
