import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.05,
            color: ColorConstants.BLACK,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
