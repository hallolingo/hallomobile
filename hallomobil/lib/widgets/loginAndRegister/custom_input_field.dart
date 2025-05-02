import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class CustomInputField extends StatelessWidget {
  final String labelText;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final bool showPasswordToggle;

  const CustomInputField({
    super.key,
    required this.labelText,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.showPasswordToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      obscureText: isPassword,
      style: TextStyle(color: ColorConstants.WHITE), // Text color
      cursorColor: ColorConstants.WHITE, // Cursor color
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: ColorConstants.WHITE,
          fontSize: 16,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: ColorConstants.WHITE,
              )
            : isPassword
                ? Icon(
                    Icons.lock,
                    color: ColorConstants.WHITE,
                  )
                : Icon(
                    Icons.email,
                    color: ColorConstants.WHITE,
                  ),
        suffixIcon: isPassword && showPasswordToggle
            ? IconButton(
                icon: Icon(
                  isPassword ? Icons.visibility : Icons.visibility_off,
                  color: ColorConstants.WHITE,
                ),
                onPressed: () {},
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }
}
