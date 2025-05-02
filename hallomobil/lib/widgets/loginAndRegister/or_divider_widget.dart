import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'package:hallomobil/constants/login/login_constants.dart';

class OrDivider extends StatelessWidget {
  final String text;
  final Color lineColor;
  final Color textColor;
  final double thickness;

  const OrDivider({
    super.key,
    this.text = LoginConstants.OR,
    this.lineColor = ColorConstants.WHITE,
    this.textColor = ColorConstants.WHITE,
    this.thickness = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: lineColor,
              thickness: thickness,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: lineColor,
              thickness: thickness,
            ),
          ),
        ],
      ),
    );
  }
}
