import 'package:flutter/material.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;

  const CustomFloatingActionButton({
    super.key,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor:
          isSelected ? ColorConstants.MAINCOLOR : ColorConstants.WHITE,
      elevation: 2,
      shape: const CircleBorder(),
      child: Icon(
        isSelected ? Icons.person : Icons.person_outline,
        color: isSelected ? ColorConstants.WHITE : ColorConstants.MAINCOLOR,
      ),
    );
  }
}
